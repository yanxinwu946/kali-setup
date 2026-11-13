#!/usr/bin/env bash
# ============================================================
# kali-setup 一键部署（Kali/Debian，需 root）
#
# 用法: ./install.sh [选项]
#   --skip  <步骤>      跳过步骤，逗号分隔
#   --only  <步骤>      只执行指定步骤，逗号分隔
#   --force-fonts       强制重新下载/安装字体
#   --ssh-root <mode>   root SSH 模式: yes|prohibit-password|no（默认 yes）
#   -h, --help          显示帮助
#
# 步骤: mirror,deps,gh-tools,payloads,locale,dotfiles,init,zshrc,node,jdk8,uv,fonts,ssh,perms
# 示例:
#   ./install.sh --skip gh-tools,payloads,jdk8,fonts  # 快速恢复，跳过下载类步骤
#   ./install.sh --only fonts,ssh        # 只补装字体、开启 root SSH
# ============================================================
set -uo pipefail

PENTEST_DIR="${PENTEST_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
export PENTEST_DIR
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# shellcheck source=scripts/_common.sh
source "$PENTEST_DIR/scripts/_common.sh"

STEPS=(mirror deps gh-tools payloads locale dotfiles init zshrc node jdk8 uv fonts ssh perms)
STEP_NAMES="$(IFS=,; echo "${STEPS[*]}")"
SKIP_LIST=","; ONLY_LIST=""
FORCE_FONTS=0
SSH_ROOT_MODE="${PENTEST_SSH_ROOT_LOGIN:-yes}"
FAILED=()

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

check_steps() {
    local token
    for token in ${1//,/ }; do
        [[ " ${STEPS[*]} " == *" $token "* ]] \
            || die "未知步骤: $token（可选: $STEP_NAMES）"
    done
}

while (($#)); do
    case "$1" in
        --skip)        check_steps "${2:?缺少参数值}"; SKIP_LIST=",$2,"; shift 2 ;;
        --skip=*)      check_steps "${1#*=}"; SKIP_LIST=",${1#*=},"; shift ;;
        --only)        check_steps "${2:?缺少参数值}"; ONLY_LIST=",$2,"; shift 2 ;;
        --only=*)      check_steps "${1#*=}"; ONLY_LIST=",${1#*=},"; shift ;;
        --force-fonts) FORCE_FONTS=1; shift ;;
        --ssh-root)    SSH_ROOT_MODE="${2:?缺少参数值}"; shift 2 ;;
        --ssh-root=*)  SSH_ROOT_MODE="${1#*=}"; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "未知参数: $1（--help 查看用法）" ;;
    esac
done

enabled() {
    local step="$1"
    [[ -n "$ONLY_LIST" && "$ONLY_LIST" != *",$step,"* ]] && return 1
    [[ "$SKIP_LIST" == *",$step,"* ]] && return 1
    return 0
}

pkg_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

require_root
if [[ "$PENTEST_DIR" != "$HOME/pentest" ]]; then
    log_warn "仓库位于 $PENTEST_DIR（非 $HOME/pentest）；如 zsh 工具路径失效，请设置 PENTEST_DIR"
fi
if ! curl -fsI --max-time 8 https://github.com >/dev/null 2>&1; then
    log_warn "GitHub 不可达：gh-tools / 字体 安装可能失败"
fi

# ============================================================
# 步骤实现
# ============================================================
do_mirror() {
    bash "$PENTEST_DIR/scripts/setup-kali-mirror.sh"
}

do_gh-tools() {
    bash "$PENTEST_DIR/scripts/install-gh-tools.sh"
}

do_payloads() {
    bash "$PENTEST_DIR/scripts/install-payloads.sh"
}

do_locale() {
    bash "$PENTEST_DIR/scripts/setup-locale-zh.sh"
}

do_deps() {
    local -a pkgs=(
        git curl wget zsh tmux vim
        fzf ripgrep bat tealdeer fd-find eza jq xsel grc
        htop btop ncdu tree zip unzip aria2 rustscan musl
        zoxide yq shellcheck lazygit httpie
        libsasl2-dev python3-dev libldap2-dev libssl-dev
        ntpsec-ntpdate rlwrap bloodyad certipy-ad mitm6 arjun enum4linux-ng
        faketime python3-pwntools
        trash-cli goshs fontconfig fonts-noto-cjk
    )
    local -a missing=() failed=()
    local p

    if ! pkg_installed kali-linux-default && ! pkg_installed kali-linux-headless; then
        log_warn "未检测到 kali-linux-default/headless；建议先安装 Kali 基础工具集"
    fi

    for p in "${pkgs[@]}"; do
        pkg_installed "$p" || missing+=("$p")
    done

    if ((${#missing[@]})); then
        log_info "需安装 ${#missing[@]} 个依赖: ${missing[*]}"
        apt-get update -qq || log_warn "apt-get update 失败，继续尝试安装"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"; then
            log_warn "批量安装失败，改为逐个安装..."
            for p in "${missing[@]}"; do
                DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$p" \
                    || failed+=("$p")
            done
        fi
        ((${#failed[@]} == 0)) || { log_warn "安装失败: ${failed[*]}"; return 1; }
    else
        log_info "系统依赖已齐全"
    fi

    # Kali 包只提供小写 bloodyad；补一个上游习惯的大写别名
    if [[ -x /usr/share/bloodyad/bin/bloodyAD ]] \
       && ! command -v bloodyAD >/dev/null 2>&1; then
        ln -sf /usr/share/bloodyad/bin/bloodyAD /usr/local/bin/bloodyAD
    fi
}

do_dotfiles() {
    local src rel

    [[ -d "$PENTEST_DIR/dotfiles" ]] \
        || { log_warn "缺少 dotfiles 目录"; return 1; }

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    while IFS= read -r -d '' src; do
        rel="${src#"$PENTEST_DIR/dotfiles/"}"
        install -Dm644 "$src" "$HOME/$rel"
    done < <(find "$PENTEST_DIR/dotfiles" -type f -print0)

    log_info "配置已下发到 $HOME"
}

do_init() {
    local -a scripts=(setup-oh-my-zsh.sh setup-zellij.sh setup-gdb.sh)
    local name path rc=0

    for name in "${scripts[@]}"; do
        path="$PENTEST_DIR/scripts/$name"
        if [[ -f "$path" ]]; then
            chmod +x "$path"
            log_info "执行: $name"
            bash "$path" || { log_warn "$name 失败，已跳过"; rc=1; }
        else
            log_warn "初始化脚本不存在: $path"
        fi
    done
    return "$rc"
}

do_zshrc() {
    local zshrc="$HOME/.zshrc" tmp
    touch "$zshrc"
    if grep -q 'pentest env' "$zshrc"; then
        log_info ".zshrc 已包含 pentest env，跳过"
        return 0
    fi

    tmp="$(mktemp)"
    {
        printf '# ===== pentest env =====\n'
        printf 'source ~/.zshrc_custom 2>/dev/null || true\n'
        printf 'source <(fzf --zsh 2>/dev/null)\n'
        printf '# =======================\n\n'
        cat "$zshrc"
    } > "$tmp"
    cat "$tmp" > "$zshrc"
    rm -f "$tmp"
    log_info "已注入 pentest env 到 .zshrc 头部"
}

do_node() {
    bash "$PENTEST_DIR/scripts/install-fnm.sh"
}

do_jdk8() {
    bash "$PENTEST_DIR/scripts/install-jdk8.sh"
}

do_uv() {
    bash "$PENTEST_DIR/scripts/install-uv-tools.sh"
}

do_fonts() {
    local -a args=()
    ((FORCE_FONTS)) && args+=(--force)
    bash "$PENTEST_DIR/scripts/install-fonts.sh" "${args[@]}"
}

do_ssh() {
    bash "$PENTEST_DIR/scripts/setup-ssh.sh" --root-login "$SSH_ROOT_MODE"
}

do_perms() {
    local dir
    for dir in scripts legacy tools payloads dicts; do
        [[ -d "$PENTEST_DIR/$dir" ]] || continue
        find "$PENTEST_DIR/$dir" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
    done
    chmod +x "$PENTEST_DIR/legacy/wintools.py" 2>/dev/null || true
    find "$PENTEST_DIR/tools/python" "$PENTEST_DIR/tools/shell" \
        -type f -exec chmod +x {} + 2>/dev/null || true
    log_info "脚本执行权限已整理"
}

# ============================================================
# 主流程
# ============================================================
log_info "仓库目录: $PENTEST_DIR"

for step in "${STEPS[@]}"; do
    if ! enabled "$step"; then
        log_warn "跳过步骤: $step"
        continue
    fi
    log_info "===== [$step] ====="
    "do_$step" || FAILED+=("$step")
done

echo
if ((${#FAILED[@]})); then
    log_warn "以下步骤未完全成功: ${FAILED[*]}"
    log_warn "可单独重跑: ./install.sh --only $(IFS=,; echo "${FAILED[*]}")"
    exit 1
fi

log_info "所有任务部署完成！"
log_info "执行 source ~/.zshrc 使环境生效"
