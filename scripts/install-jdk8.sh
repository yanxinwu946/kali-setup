#!/usr/bin/env bash
# ============================================================
# 安装 JDK 8u202 到 /opt（Huawei 镜像）
#
# 用法: install-jdk8.sh [--force]
#
# 说明:
#   - 下载 jdk-8u202-linux-x64.tar.gz 并校验 sha256
#   - 解压到 /opt/jdk1.8.0_202，创建 /opt/jdk8 符号链接
#   - 不修改系统默认 Java；供 IDEA 或工具按需选择
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

JDK_DIR="/opt/jdk1.8.0_202"
JDK_LINK="/opt/jdk8"
JDK_URL="https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz"
JDK_SHA256="9a5c32411a6a06e22b69c495b7975034409fa1652d03aeb8eb5b6f59fd4594e0"

FORCE=0
while (($#)); do
    case "$1" in
        --force|-f) FORCE=1; shift ;;
        -h|--help)  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          log_err "未知参数: $1"; exit 2 ;;
    esac
done

require_root

[[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "amd64" ]] \
    || die "当前脚本只提供 x86_64 JDK 8"

if (( ! FORCE )) && [[ -x "$JDK_DIR/bin/java" ]]; then
    ln -sfn "$JDK_DIR" "$JDK_LINK"
    log_info "JDK 8 已安装: $("$JDK_DIR/bin/java" -version 2>&1 | head -n1)"
    exit 0
fi

command -v curl >/dev/null 2>&1 || die "需要 curl"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
progress=(--progress-bar)
[[ -t 1 ]] || progress=(-sS)

log_info "下载 JDK 8u202..."
curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 \
    "${progress[@]}" -o "$TMP/jdk8.tar.gz" "$JDK_URL" \
    || die "JDK 下载失败"

echo "$JDK_SHA256  $TMP/jdk8.tar.gz" | sha256sum -c - >/dev/null \
    || die "JDK sha256 校验失败"

rm -rf "$JDK_DIR"
tar -xzf "$TMP/jdk8.tar.gz" -C /opt
[[ -x "$JDK_DIR/bin/java" ]] || die "解压后未找到 $JDK_DIR/bin/java"
ln -sfn "$JDK_DIR" "$JDK_LINK"

log_info "JDK 8 安装完成: $("$JDK_DIR/bin/java" -version 2>&1 | head -n1)"
log_info "JAVA8_HOME=$JDK_LINK"
