#!/usr/bin/env bash
# ============================================================
# 安装 fnm 并设置 Node.js 默认版本
#
# 用法: install-fnm.sh
#
# 说明:
#   - fnm 由 ghr 安装到 ~/.local/bin
#   - 默认安装最新 LTS；可用 PENTEST_NODE_VERSION 指定版本
#   - 下载走 npmmirror，可用 FNM_NODE_DIST_MIRROR 覆盖
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

export PATH="$HOME/.local/bin:$PATH"
export FNM_NODE_DIST_MIRROR="${FNM_NODE_DIST_MIRROR:-https://npmmirror.com/mirrors/node/}"

if [[ -n "${PENTEST_NODE_VERSION:-}" ]]; then
    node_version="$PENTEST_NODE_VERSION"
    install_args=("$node_version")
    default_version="$node_version"
else
    install_args=(--lts)
    default_version="lts-latest"
fi

if ! command -v ghr >/dev/null 2>&1; then
    bash "$SCRIPT_DIR/install-ghr.sh"
fi

if ! command -v fnm >/dev/null 2>&1; then
    log_info "安装 fnm..."
    ghr install Schniz/fnm
fi
command -v fnm >/dev/null 2>&1 || die "fnm 安装失败"

log_info "安装 Node.js: ${install_args[*]}"
fnm install "${install_args[@]}"
fnm default "$default_version"

eval "$(fnm env --shell bash)"
log_info "Node.js: $(node -v 2>/dev/null) / npm: $(npm -v 2>/dev/null)"
log_info "fnm default: $(fnm default 2>/dev/null)"
