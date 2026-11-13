#!/usr/bin/env bash
# ============================================================
# 切换 Kali apt 镜像源
#
# 用法: setup-kali-mirror.sh [选项]
#   --mirror <名称|URL>  镜像: tuna|ustc|aliyun|huawei|official（默认 tuna）
#   --list               列出内置镜像
#   --no-update          只改配置，不执行 apt-get update
#   --restore            恢复上次修改前的源配置
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

declare -A MIRRORS=(
    [tuna]="https://mirrors.tuna.tsinghua.edu.cn/kali"
    [ustc]="https://mirrors.ustc.edu.cn/kali"
    [aliyun]="https://mirrors.aliyun.com/kali"
    [huawei]="https://mirrors.huaweicloud.com/kali"
    [official]="http://http.kali.org/kali"
)

MIRROR="${PENTEST_KALI_MIRROR:-tuna}"
DO_UPDATE=1
RESTORE=0

while (($#)); do
    case "$1" in
        --mirror)      MIRROR="${2:?缺少参数值}"; shift 2 ;;
        --mirror=*)    MIRROR="${1#*=}"; shift ;;
        --no-update)   DO_UPDATE=0; shift ;;
        --restore)     RESTORE=1; shift ;;
        --list)
            for name in tuna ustc aliyun huawei official; do
                printf '  %-9s %s\n' "$name" "${MIRRORS[$name]}"
            done
            exit 0 ;;
        -h|--help)     sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) log_err "未知参数: $1"; exit 2 ;;
    esac
done

require_root
if ! grep -q '^ID=kali' /etc/os-release 2>/dev/null; then
    log_err "当前系统不是 Kali Linux，已退出"
    exit 1
fi

restore_previous() {
    local f restored=0
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*; do
        [[ -f "$f.pentest.bak" ]] || continue
        cp -a "$f.pentest.bak" "$f"
        log_info "已恢复: $f"
        restored=1
    done
    if (( restored == 0 )); then
        log_warn "未找到 .pentest.bak 备份"
        return 1
    fi
    apt-get update -qq || log_warn "恢复后 apt-get update 仍失败"
}

if (( RESTORE )); then
    restore_previous
    exit $?
fi

# ---------- 解析镜像 ----------
if [[ "$MIRROR" == *://* ]]; then
    MIRROR_URL="${MIRROR%/}"
    MIRROR_LABEL="$MIRROR_URL"
else
    MIRROR_URL="${MIRRORS[$MIRROR]:-}"
    [[ -n "$MIRROR_URL" ]] || { log_err "未知镜像: $MIRROR（--list 查看）"; exit 2; }
    MIRROR_LABEL="$MIRROR"
fi

if command -v curl >/dev/null 2>&1; then
    log_info "检测镜像: $MIRROR_URL"
    curl -fsIL --max-time 15 -o /dev/null "$MIRROR_URL/dists/kali-rolling/Release" \
        || { log_err "镜像不可用: $MIRROR_URL"; exit 1; }
fi

# ---------- 收集 Kali 源文件 ----------
mapfile -t FILES < <(
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        [[ -f "$f" ]] || continue
        grep -qi 'kali' "$f" || continue
        printf '%s\n' "$f"
    done
)

TOUCHED=(); CREATED=()

if ((${#FILES[@]} == 0)); then
    mkdir -p /etc/apt/sources.list.d
    default_file="/etc/apt/sources.list.d/kali.sources"
    {
        echo "# Managed by kali-setup (scripts/setup-kali-mirror.sh)"
        echo "Types: deb"
        echo "URIs: $MIRROR_URL/"
        echo "Suites: kali-rolling"
        echo "Components: main contrib non-free non-free-firmware"
        if [[ -e /usr/share/keyrings/kali-archive-keyring.gpg ]]; then
            echo "Signed-By: /usr/share/keyrings/kali-archive-keyring.gpg"
        fi
    } > "$default_file"
    CREATED+=("$default_file")
    log_info "已创建 $default_file"
else
    for f in "${FILES[@]}"; do
        [[ -f "$f.pentest.bak" ]] || cp -a "$f" "$f.pentest.bak"
        before="$(mktemp)"
        cp -a "$f" "$before"

        if grep -qiE '^[[:space:]]*URIs:.*kali' "$f"; then
            sed -i -E "s#^[[:space:]]*URIs:.*#URIs: ${MIRROR_URL}/#" "$f"
        elif grep -qiE '^[[:space:]]*deb(-src)?[[:space:]].*kali' "$f"; then
            sed -i -E "/kali-rolling/ s#^([[:space:]]*deb(-src)?[[:space:]]+(\[[^]]*\][[:space:]]+)?)[^[:space:]]+#\1${MIRROR_URL}#" "$f"
        else
            log_warn "跳过无法识别的源文件: $f"
            rm -f "$before"
            continue
        fi

        if ! cmp -s "$f" "$before"; then
            TOUCHED+=("$f")
            log_info "已更新: $f"
        fi
        rm -f "$before"
    done
fi

if ((${#TOUCHED[@]} == 0 && ${#CREATED[@]} == 0)); then
    log_info "源配置已是 $MIRROR_URL，无需修改"
fi

# ---------- apt 校验，失败回滚 ----------
if (( DO_UPDATE )); then
    log_info "执行 apt-get update..."
    if ! apt-get update -qq; then
        log_err "apt-get update 失败，正在回滚源配置..."
        for f in "${TOUCHED[@]}"; do
            if [[ -f "$f.pentest.bak" ]]; then
                cp -a "$f.pentest.bak" "$f"
            fi
        done
        for f in "${CREATED[@]}"; do
            rm -f "$f"
        done
        apt-get update -qq || true
        exit 1
    fi
else
    log_warn "已跳过 apt-get update"
fi

log_info "Kali 镜像已切换: $MIRROR_LABEL -> $MIRROR_URL"
grep -rhE '^(URIs:|deb(-src)?[[:space:]])' \
    /etc/apt/sources.list /etc/apt/sources.list.d/*.sources \
    /etc/apt/sources.list.d/*.list 2>/dev/null \
    | grep -i kali | sed 's/^/    /' | head -5 || true
