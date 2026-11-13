#!/usr/bin/env bash

# Help function
show_help() {
    echo "Usage: $(basename $0) <target_ip> [wordlist_path]"
    echo "Options:"
    echo "  target_ip      Target IP address (required)"
    echo "  wordlist_path  Path to wordlist (default: raft-large-directories-lowercase.txt)"
    exit 0
}

# Check for help flag
[[ "$1" == "-h" || "$1" == "--help" ]] && show_help

# Validate target IP
[[ -z "$1" ]] && { echo "Error: Target IP required"; show_help; }

# Set variables
TARGET_IP="$1"
WORDLIST="${2:-/usr/share/seclists/Discovery/Web-Content/raft-large-directories-lowercase.txt}"
THREADS=${THREADS_ENV:-10}
TIMEOUT=${TIMEOUT_ENV:-2}

# Check dependencies and wordlist
command -v rsync >/dev/null 2>&1 || { echo "Error: rsync not found"; exit 1; }
[[ ! -f "$WORDLIST" ]] && { echo "Error: Wordlist not found"; exit 1; }

echo "[*] Starting rsync brute-force on $TARGET_IP with $THREADS threads, ${TIMEOUT}s timeout"

# Test module function
test_module() {
    local module=$1
    if timeout "$TIMEOUT" rsync "$TARGET_IP::$module" >/dev/null 2>&1; then
        echo "[+] Found module: $module"
        rsync -av "$TARGET_IP::$module" 2>&1
        return 0
    fi
    return 1
}

# Parallel processing setup
export -f test_module
export TARGET_IP TIMEOUT
temp_fifo="/tmp/rsync_brute_$$"
mkfifo "$temp_fifo"
exec 3<>"$temp_fifo"
rm "$temp_fifo"

# Initialize semaphore
for ((i=0; i<THREADS; i++)); do echo >&3; done

# Main loop
found=0
while IFS= read -r module; do
    read -u 3
    {
        if test_module "$module"; then
            ((found++))
        fi
        echo >&3
    } &
done < "$WORDLIST"

wait
exec 3>&-

echo
[[ $found -eq 0 ]] && { echo "[-] No accessible rsync modules found"; exit 1; } || echo "[+] Found $found accessible rsync modules"