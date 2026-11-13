#!/usr/bin/env bash
# 安装 uv 并部署 Python 工具

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

if ! command -v uv &>/dev/null; then
    log_info "安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH"
fi

log_info "部署 Python 工具..."
UV_TOOLS=(
    "evil-winrm-py[kerberos]"
    "penelope-shell-handler"
    "git+https://github.com/maurosoria/dirsearch"
    #"fenjing"
    "githacker"
    #"wesng"
    #"xortool"
    #"uro"
    #"git+https://github.com/r0oth3x49/ghauri"
    #"git+https://github.com/Yanxinwu946/hackmyvm-cli"
    "git+https://github.com/manesec/pipx4adtools"
    #"git+https://github.com/aniqfakhrul/powerview.py"
    #"git+https://github.com/Esonhugh/Gopherus3.git"
)

for tool in "${UV_TOOLS[@]}"; do
    log_info "安装/更新: $tool"
    uv tool install "$tool" --force || log_warn "$tool 安装失败，请检查网络或源"
done

echo "[+] UV 工具部署完成"
