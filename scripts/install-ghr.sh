#!/usr/bin/env bash
# ============================================================
# 安装/更新 ghr（GitHub Release 工具管理器）
#
# 用法: install-ghr.sh [--force]
#
# 说明:
#   - 通过官方安装脚本安装到 ~/.local/bin/ghr（自动校验签名）
#   - 不修改 shell rc，PATH 由 dotfiles/.zshrc_custom 管理
#   - 已安装时跳过；--force 强制更新
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

FORCE=0
while (($#)); do
    case "$1" in
        --force|-f) FORCE=1; shift ;;
        -h|--help)  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          log_err "未知参数: $1"; exit 2 ;;
    esac
done

export PATH="${GHR_BIN_DIR:-$HOME/.local/bin}:$PATH"

use_gh_token

if (( ! FORCE )) && command -v ghr >/dev/null 2>&1; then
    log_info "ghr 已安装: $(ghr version 2>/dev/null | head -n1)"
    exit 0
fi

log_info "安装 ghr..."
GHR_NO_PATH_ADD=1 \
    sh -c 'curl -fsSL https://raw.githubusercontent.com/cataggar/ghr/main/install.sh | sh' \
    || die "ghr 安装失败，请检查网络或代理"
hash -r 2>/dev/null || true

command -v ghr >/dev/null 2>&1 \
    || die "ghr 安装后不在 PATH（${GHR_BIN_DIR:-$HOME/.local/bin}）"
log_info "ghr 安装成功: $(ghr version 2>/dev/null | head -n1)"
