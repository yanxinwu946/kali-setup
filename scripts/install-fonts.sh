#!/usr/bin/env bash
# ============================================================
# 安装 JetBrains Maple Mono Nerd Font（kitty / p10k 所需）
#
# 用法:
#   install-fonts.sh [--force] [--variant NF-XX-XX-XX]
#
# 说明:
#   - 字体已安装时直接跳过；--force 强制重新下载
#   - 默认变体 NF-XX-XX-XX = Nerd Font + 连字 + 中日字形
#   - root 安装到 /usr/local/share/fonts，普通用户安装到 ~/.local/share/fonts
#   - 只安装 Regular/Bold/Italic/BoldItalic，避免整包几十个字重占空间
#   - PENTEST_FONT_ZIP 可指定本地 zip，离线/免重复下载
#   - 同时写入 qterminal 字体（fontFamily/fontSize）
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

FORCE=0
VARIANT="${PENTEST_FONT_VARIANT:-NF-XX-XX-XX}"
FONT_FAMILY_RE='JetBrains Maple Mono'

while (($#)); do
    case "$1" in
        --force)       FORCE=1; shift ;;
        --variant)     VARIANT="${2:?缺少参数值}"; shift 2 ;;
        --variant=*)   VARIANT="${1#*=}"; shift ;;
        -h|--help)     sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) log_err "未知参数: $1"; exit 2 ;;
    esac
done

# 注意: 不能直接 `fc-list | grep -q`——grep -q 提前退出会让 fc-list 收到
# SIGPIPE，在 pipefail 下整条管道被判为失败。这里先取第一条匹配结果。
font_entry() {
    fc-list 2>/dev/null | grep -i "$FONT_FAMILY_RE" | head -n1 || true
}

# ---------- qterminal 字体配置 ----------
QTERM_FONT="${PENTEST_QTERMINAL_FONT:-$FONT_FAMILY_RE}"
QTERM_SIZE="${PENTEST_QTERMINAL_FONT_SIZE:-14}"

configure_qterminal() {
    local ini="${XDG_CONFIG_HOME:-$HOME/.config}/qterminal.org/qterminal.ini"
    local changed=0

    if ! command -v qterminal >/dev/null 2>&1 && [[ ! -f "$ini" ]]; then
        log_info "未检测到 qterminal，跳过终端字体配置"
        return 0
    fi

    mkdir -p "$(dirname "$ini")"
    if [[ ! -f "$ini" ]]; then
        printf '[General]\nfontFamily=%s\nfontSize=%s\n' \
            "$QTERM_FONT" "$QTERM_SIZE" > "$ini"
        log_info "已创建 qterminal 配置: $QTERM_FONT ${QTERM_SIZE}pt"
        return 0
    fi

    [[ -f "$ini.pentest.bak" ]] || cp -a "$ini" "$ini.pentest.bak" 2>/dev/null || true

    if ! grep -q '^\[General\]' "$ini"; then
        printf '\n[General]\nfontFamily=%s\nfontSize=%s\n' \
            "$QTERM_FONT" "$QTERM_SIZE" >> "$ini"
        log_info "已追加 [General]，qterminal 字体: $QTERM_FONT ${QTERM_SIZE}pt"
        changed=1
    else
        if grep -q '^fontFamily=' "$ini"; then
            if ! grep -Fqx "fontFamily=$QTERM_FONT" "$ini"; then
                sed -i "s|^fontFamily=.*|fontFamily=$QTERM_FONT|" "$ini" \
                    || { log_warn "写入 qterminal fontFamily 失败"; return 0; }
                changed=1
            fi
        else
            sed -i "/^\[General\]/a fontFamily=$QTERM_FONT" "$ini" \
                || { log_warn "写入 qterminal fontFamily 失败"; return 0; }
            changed=1
        fi

        if grep -q '^fontSize=' "$ini"; then
            if ! grep -Fqx "fontSize=$QTERM_SIZE" "$ini"; then
                sed -i "s|^fontSize=.*|fontSize=$QTERM_SIZE|" "$ini" \
                    || { log_warn "写入 qterminal fontSize 失败"; return 0; }
                changed=1
            fi
        else
            sed -i "/^\[General\]/a fontSize=$QTERM_SIZE" "$ini" \
                || { log_warn "写入 qterminal fontSize 失败"; return 0; }
            changed=1
        fi
    fi

    if ((changed)); then
        log_info "已设置 qterminal 字体: $QTERM_FONT ${QTERM_SIZE}pt"
    else
        log_info "qterminal 字体已是: $QTERM_FONT ${QTERM_SIZE}pt"
    fi

    if command -v pgrep >/dev/null 2>&1 && pgrep -x qterminal >/dev/null 2>&1; then
        log_warn "qterminal 正在运行：请关闭所有窗口后重新打开；若配置被旧窗口覆盖，重跑本脚本"
    fi
}

# ---------- 已安装则跳过 ----------
current_font="$(font_entry)"
if (( ! FORCE )) && [[ -n "$current_font" ]]; then
    log_info "字体已安装: $(cut -d: -f2- <<<"$current_font" | sed 's/^ //')"
    configure_qterminal
    exit 0
fi

command -v fc-cache >/dev/null 2>&1 || {
    log_err "缺少 fontconfig（fc-cache），请先安装"
    exit 1
}

if [[ $EUID -eq 0 ]]; then
    FONT_DIR="${PENTEST_FONT_DIR:-/usr/local/share/fonts/JetBrainsMapleMono}"
else
    FONT_DIR="${PENTEST_FONT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMapleMono}"
fi

ASSET="JetBrainsMapleMono-${VARIANT}.zip"
URL="https://github.com/SpaceTimee/Fusion-JetBrainsMapleMono/releases/latest/download/${ASSET}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -n "${PENTEST_FONT_ZIP:-}" ]]; then
    [[ -f "$PENTEST_FONT_ZIP" ]] || { log_err "字体包不存在: $PENTEST_FONT_ZIP"; exit 1; }
    log_info "使用本地字体包: $PENTEST_FONT_ZIP"
    cp -f "$PENTEST_FONT_ZIP" "$TMP/font.zip"
else
    log_info "下载字体: $ASSET"
    progress=(--progress-bar)
    [[ -t 1 ]] || progress=(-sS)   # 非交互环境不刷进度条
    if ! curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 \
            "${progress[@]}" -o "$TMP/font.zip" "$URL"; then
        log_err "字体下载失败（检查网络或变体名称: $VARIANT）"
        exit 1
    fi
fi

unzip -tq "$TMP/font.zip" >/dev/null || { log_err "字体压缩包损坏"; exit 1; }
mkdir -p "$TMP/fonts" "$FONT_DIR"

# 只解压常用字重（整包约 300MB，4 个字重约 76MB）
mapfile -t wanted < <(
    unzip -Z1 "$TMP/font.zip" 2>/dev/null \
      | grep -Ei '[-_](regular|bold|italic|bolditalic)\.(ttf|otf)$' || true
)
if ((${#wanted[@]})); then
    unzip -q -o "$TMP/font.zip" "${wanted[@]}" -d "$TMP/fonts"
else
    unzip -q -o "$TMP/font.zip" -d "$TMP/fonts"
fi

# 文件名不符合预期时回退到解压全部字体
mapfile -t FONT_FILES < <(
    find "$TMP/fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \)
)
if ((${#FONT_FILES[@]} == 0)); then
    unzip -q -o "$TMP/font.zip" -d "$TMP/fonts"
    mapfile -t FONT_FILES < <(
        find "$TMP/fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \)
    )
fi
(( ${#FONT_FILES[@]} > 0 )) || { log_err "压缩包内未找到字体文件"; exit 1; }
(( ${#FONT_FILES[@]} > 0 )) || { log_err "压缩包内未找到字体文件"; exit 1; }

for f in "${FONT_FILES[@]}"; do
    install -Dm644 "$f" "$FONT_DIR/$(basename "$f")"
done
log_info "已安装 ${#FONT_FILES[@]} 个字体文件到 $FONT_DIR"

# 必须刷新全局缓存：只刷新子目录时，父目录缓存仍不包含新目录，fc-list 会漏掉字体
fc-cache -f >/dev/null 2>&1 || true

current_font="$(font_entry)"
if [[ -n "$current_font" ]]; then
    log_info "字体已生效: $(cut -d: -f2- <<<"$current_font" | sed 's/^ //')"
else
    log_warn "字体已复制但 fc-list 未识别，可尝试重新登录或执行 fc-cache -fv"
    exit 1
fi

configure_qterminal
