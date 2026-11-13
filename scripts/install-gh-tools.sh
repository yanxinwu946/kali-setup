#!/usr/bin/env bash
# ============================================================
# 通过 ghr 批量安装/更新 GitHub 工具
#
# 用法: install-gh-tools.sh [--force]
#
# 说明:
#   - 工具清单: scripts/ghr-tools.txt
#   - 默认只安装缺失项；--force 重新安装/更新全部
#   - ghr 与工具安装到 ~/.local/bin，无需 root
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

TOOLS_FILE="$SCRIPT_DIR/ghr-tools.txt"
FORCE=0
while (($#)); do
    case "$1" in
        --force|-f) FORCE=1; shift ;;
        -h|--help)  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          log_err "未知参数: $1"; exit 2 ;;
    esac
done

[[ -f "$TOOLS_FILE" ]] || die "缺少工具清单: $TOOLS_FILE"

export PATH="${GHR_BIN_DIR:-$HOME/.local/bin}:$PATH"

use_gh_token

if (( FORCE )) || ! command -v ghr >/dev/null 2>&1; then
    args=()
    (( FORCE )) && args+=(--force)
    bash "$SCRIPT_DIR/install-ghr.sh" "${args[@]}"
fi

mapfile -t all < <(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$TOOLS_FILE" \
    | grep -v '^$')
((${#all[@]})) || die "工具清单为空: $TOOLS_FILE"

installed="$(ghr list --ids 2>/dev/null || true)"
todo=()
for src in "${all[@]}"; do
    if (( FORCE )); then
        todo+=("$src")
        continue
    fi
    id="${src%@*}"
    id="${id,,}"
    grep -qxF "$id" <<<"$installed" || todo+=("$src")
done

rc=0
if ((${#todo[@]})); then
    log_info "安装/更新 GitHub 工具: ${todo[*]}"
    ghr install --keep-going "${todo[@]}" || rc=$?
else
    log_info "GitHub 工具已齐全"
fi

# yazi 的 zsh 补全不在 ghr 的链接范围内，从工具目录补装
install_yazi_completions() {
    local root="${GHR_TOOL_DIR:-$HOME/.local/share/ghr/tools}"
    local dest="${ZSH_COMPLETION_DIR:-/usr/local/share/zsh/site-functions}"
    local src

    src="$(find "$root" -type f -path '*/completions/_yazi' -print -quit 2>/dev/null || true)"
    [[ -n "$src" && -f "${src%/_yazi}/_ya" ]] || return 0

    if [[ $EUID -ne 0 ]]; then
        log_warn "非 root：跳过 yazi zsh 补全安装"
        return 0
    fi

    install -Dm644 "$src" "$dest/_yazi"
    install -Dm644 "${src%/_yazi}/_ya" "$dest/_ya"
    log_info "已安装 yazi zsh 补全: $dest"
}
install_yazi_completions

log_info "已管理的 GitHub 工具:"
ghr list --ids || true
exit "$rc"
