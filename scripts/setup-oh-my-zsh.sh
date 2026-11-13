#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

# --- 1. 安装 Oh My Zsh  ---
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 2. 安装 P10k 及其它插件 ---
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
if [[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
fi

clone_plugin() {
    if [[ ! -d "${ZSH_CUSTOM}/plugins/$2" ]]; then
        git clone --depth=1 "$1" "${ZSH_CUSTOM}/plugins/$2"
    fi
}
clone_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "zsh-syntax-highlighting"
clone_plugin "https://github.com/nyoungstudios/zsh-history-on-success" "zsh-history-on-success"

# --- 3. 修改 .zshrc ---
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
SED_OPT=(-i)
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_OPT=(-i "")
fi

if grep -q '^ZSH_THEME=' "$ZSHRC"; then
    sed "${SED_OPT[@]}" 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
fi

if grep -q '^plugins=' "$ZSHRC"; then
    sed "${SED_OPT[@]}" "s/^plugins=(.*/plugins=(git z sudo extract eza zsh-autosuggestions zsh-syntax-highlighting)/" "$ZSHRC"
else
    echo 'plugins=(git z sudo extract eza zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
fi

# 确保在 .zshrc 底部加载 .p10k.zsh
if ! grep -q "source ~/.p10k.zsh" "$ZSHRC"; then
    echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> "$ZSHRC"
fi

log_info "P10k 组件安装完成，配置将由主脚本同步。"
