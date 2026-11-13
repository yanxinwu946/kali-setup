#!/usr/bin/env bash
# ============================================================
# 通过 ghr 下载后渗透载荷
#
# 用法: install-payloads.sh [--force]
#
# 说明:
#   - 清单: scripts/ghr-payloads.txt
#   - 已存在时跳过；--force 重新下载全部
#   - 下载经 ghr 校验（GitHub digest / checksum）
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

MANIFEST="$SCRIPT_DIR/ghr-payloads.txt"
PENTEST_DIR="${PENTEST_DIR:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
FORCE=0
while (($#)); do
    case "$1" in
        --force|-f) FORCE=1; shift ;;
        -h|--help)  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          log_err "未知参数: $1"; exit 2 ;;
    esac
done

[[ -f "$MANIFEST" ]] || die "缺少载荷清单: $MANIFEST"
export PATH="${GHR_BIN_DIR:-$HOME/.local/bin}:$PATH"

use_gh_token

command -v ghr >/dev/null 2>&1 || bash "$SCRIPT_DIR/install-ghr.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

installed=(); skipped=(); failed=()

while IFS='|' read -r spec dest type member; do
    [[ -z "$spec" || "$spec" == \#* ]] && continue
    spec="${spec%$'\r'}"

    dest_abs="$PENTEST_DIR/$dest"
    if [[ -f "$dest_abs" ]] && (( ! FORCE )); then
        skipped+=("$dest")
        continue
    fi

    log_info "下载: $spec"
    asset="$TMP/asset"
    if ! ghr download "$spec" -o "$asset" --quiet; then
        log_err "下载失败: $spec"
        failed+=("$spec")
        continue
    fi

    src=""
    case "$type" in
        raw)
            src="$asset"
            ;;
        gz)
            gunzip -c "$asset" > "$TMP/out"
            src="$TMP/out"
            ;;
        zip|tar.gz)
            rm -rf "$TMP/x"; mkdir -p "$TMP/x"
            if [[ "$type" == "zip" ]]; then
                unzip -q -o "$asset" -d "$TMP/x" || { failed+=("$spec"); continue; }
            else
                tar -xzf "$asset" -C "$TMP/x" || { failed+=("$spec"); continue; }
            fi
            src="$(find "$TMP/x" -type f -name "$member" -print -quit)"
            ;;
        *)
            log_err "未知类型: $type（$spec）"
            failed+=("$spec")
            continue
            ;;
    esac

    if [[ -z "$src" || ! -f "$src" ]]; then
        log_err "压缩包内未找到: ${member:-$dest}（$spec）"
        failed+=("$spec")
        continue
    fi

    install -Dm755 "$src" "$dest_abs"
    installed+=("$dest")
done < <(grep -vE '^[[:space:]]*(#|$)' "$MANIFEST")

echo
if ((${#failed[@]})); then
    log_err "以下载荷失败: ${failed[*]}"
    exit 1
fi
log_info "载荷就绪: ${#installed[@]} 个更新, ${#skipped[@]} 个跳过"
