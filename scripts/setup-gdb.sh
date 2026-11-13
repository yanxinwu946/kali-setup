#!/usr/bin/env bash
# 配置 GDB 默认加载 PEDA（Kali 默认自带 gdb-peda）
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

PEDA_SRC="/usr/share/gdb-peda/peda.py"
GDBINIT="$HOME/.gdbinit"

if [[ -f "$PEDA_SRC" ]]; then
    printf 'source %s\n' "$PEDA_SRC" > "$GDBINIT"
    log_info "已写入 $GDBINIT (加载 $PEDA_SRC)"
else
    log_warn "未找到 $PEDA_SRC，跳过 GDB 配置"
fi
