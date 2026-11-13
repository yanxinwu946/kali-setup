# ============================================================
# 终端语言（下发到 ~/.zshenv）
# 系统/GUI 保持中文（setup-locale-zh.sh），zsh 终端统一英文
# ~/.zshenv 对所有 zsh 生效：交互式、非交互式、ssh 远程命令
# 恢复中文终端：注释以下三行
# LANGUAGE 优先级高于 LC_ALL，必须一并覆盖
# ============================================================
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Node.js：fnm 默认版本（交互式 shell 由 .zshrc_custom 的 fnm env 接管）
if [[ -d "$HOME/.local/share/fnm/aliases/default/bin" ]]; then
    export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"
fi
