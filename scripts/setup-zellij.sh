#!/usr/bin/env bash
# 同步 zellij 配置（zellij 由 gh-tools 步骤通过 ghr 安装）
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

command -v zellij >/dev/null 2>&1 \
    || { log_warn "zellij 未安装（先运行 ./install.sh --only gh-tools）"; exit 0; }

CONF_DIR="$HOME/.config/zellij"
CONF_FILE="$CONF_DIR/config.kdl"
PENTEST_DIR="${PENTEST_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
REPO_CONF="$PENTEST_DIR/dotfiles/.config/zellij/config.kdl"

mkdir -p "$CONF_DIR"

if [[ -f "$REPO_CONF" ]]; then
    cp -f "$REPO_CONF" "$CONF_FILE"
    log_info "已从仓库同步 Zellij 配置"
else
    log_warn "未找到仓库配置，生成默认配置并应用主题"
    zellij setup --dump-config > "$CONF_FILE"
    sed -i 's|^// theme "default"|theme "catppuccin-mocha"|' "$CONF_FILE"
    echo 'show_startup_tips false' >> "$CONF_FILE"
fi

log_info "Zellij 配置完成，输入 'zellij' 即可启动"
