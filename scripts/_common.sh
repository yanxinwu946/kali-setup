#!/usr/bin/env bash
# ============================================================
# 共享日志/基础函数（由同目录脚本 source，不单独执行）
# 调用方需自行设置 set -euo pipefail
# ============================================================

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
log_info() { echo -e "${G}[+]${NC} $*"; }
log_warn() { echo -e "${Y}[*]${NC} $*"; }
log_err()  { echo -e "${R}[-]${NC} $*" >&2; }
die()      { log_err "$*"; exit 1; }
have()     { command -v "$1" >/dev/null 2>&1; }
require_root() {
    [[ $EUID -eq 0 ]] || die "需要 root（本仓库按 root 单用户环境设计）"
}

# 已登录 gh 时复用 token，避免 ghr/GitHub API 限流
use_gh_token() {
    [[ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]] && return 0
    command -v gh >/dev/null 2>&1 || return 0
    local token
    token="$(gh auth token 2>/dev/null || true)"
    [[ -n "$token" ]] && export GH_TOKEN="$token"
    return 0
}
