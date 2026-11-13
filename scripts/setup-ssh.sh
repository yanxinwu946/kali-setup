#!/usr/bin/env bash
# ============================================================
# 开启 root SSH 登录（幂等、可校验、失败自动回滚）
#
# 用法:
#   setup-ssh.sh [--root-login yes|prohibit-password|no]
#                [--password-auth yes|no|keep] [--no-restart]
#
# 环境变量:
#   PENTEST_SSH_ROOT_LOGIN     默认 yes
#   PENTEST_SSH_PASSWORD_AUTH  默认 keep（不改动现有 PasswordAuthentication）
#
# 说明:
#   - 配置写入 /etc/ssh/sshd_config.d/00-pentest-root.conf（优先级最高）
#   - 写入后用 sshd -t 校验语法，失败则删除 drop-in 并退出
#   - 默认 yes = 允许 root 密码/密钥登录；prohibit-password = 仅允许密钥
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

ROOT_LOGIN="${PENTEST_SSH_ROOT_LOGIN:-yes}"
PASSWORD_AUTH="${PENTEST_SSH_PASSWORD_AUTH:-keep}"
DO_RESTART=1
DROPIN="/etc/ssh/sshd_config.d/00-pentest-root.conf"

while (($#)); do
    case "$1" in
        --root-login)      ROOT_LOGIN="${2:?缺少参数值}"; shift 2 ;;
        --root-login=*)    ROOT_LOGIN="${1#*=}"; shift ;;
        --password-auth)   PASSWORD_AUTH="${2:?缺少参数值}"; shift 2 ;;
        --password-auth=*) PASSWORD_AUTH="${1#*=}"; shift ;;
        --no-restart)      DO_RESTART=0; shift ;;
        -h|--help)
            sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) log_err "未知参数: $1"; exit 2 ;;
    esac
done

case "$ROOT_LOGIN" in
    yes|prohibit-password|without-password|forced-commands-only|no) ;;
    *) log_err "--root-login 取值无效: $ROOT_LOGIN"; exit 2 ;;
esac
case "$PASSWORD_AUTH" in
    yes|no|keep) ;;
    *) log_err "--password-auth 取值无效: $PASSWORD_AUTH"; exit 2 ;;
esac

require_root

# ---------- 依赖 ----------
if ! command -v sshd >/dev/null 2>&1 && [[ ! -x /usr/sbin/sshd ]]; then
    log_warn "未安装 openssh-server，尝试安装..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server \
        || { log_err "openssh-server 安装失败"; exit 1; }
fi
SSHD_BIN="$(command -v sshd || echo /usr/sbin/sshd)"

# ---------- 主机密钥（缺失时 sshd 无法启动） ----------
mkdir -p /run/sshd
if ! compgen -G '/etc/ssh/ssh_host_*_key' >/dev/null; then
    log_warn "未找到 SSH 主机密钥，正在生成..."
    ssh-keygen -A
fi

# ---------- 确保主配置加载 drop-in ----------
MAIN_CFG="/etc/ssh/sshd_config"
BACKUP=""
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
mkdir -p /etc/ssh/sshd_config.d
if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$MAIN_CFG"; then
    log_warn "sshd_config 未包含 drop-in 目录，正在添加 Include（优先于主配置生效）"
    BACKUP="$(mktemp)"
    cp -a "$MAIN_CFG" "$BACKUP"
    trap 'rm -f "$tmp" "$BACKUP"' EXIT
    sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "$MAIN_CFG"
fi

# ---------- 写入 drop-in ----------
{
    echo "# Managed by kali-setup (scripts/setup-ssh.sh)"
    echo "PermitRootLogin $ROOT_LOGIN"
    if [[ "$PASSWORD_AUTH" != "keep" ]]; then
        echo "PasswordAuthentication $PASSWORD_AUTH"
    fi
} > "$tmp"

install -m 644 "$tmp" "$DROPIN"
if ! "$SSHD_BIN" -t; then
    rm -f "$DROPIN"
    if [[ -n "$BACKUP" ]]; then
        cp -a "$BACKUP" "$MAIN_CFG"
    fi
    log_err "sshd 配置校验失败，已回滚"
    exit 1
fi
log_info "已写入 $DROPIN (PermitRootLogin $ROOT_LOGIN)"

# ---------- 启动 / 重载 ----------
if (( DO_RESTART )); then
    if [[ -d /run/systemd/system ]]; then
        systemctl enable ssh >/dev/null 2>&1 || true
        systemctl restart ssh 2>/dev/null || systemctl restart sshd
    elif command -v service >/dev/null 2>&1; then
        service ssh restart 2>/dev/null || service sshd restart
    elif pgrep -x sshd >/dev/null 2>&1; then
        pkill -HUP -x sshd
    else
        "$SSHD_BIN"
    fi
    log_info "sshd 已重载"
fi

# ---------- 校验与提示 ----------
"$SSHD_BIN" -t || { log_err "sshd 配置无效"; exit 1; }
effective="$("$SSHD_BIN" -T 2>/dev/null | grep -iE '^(permitrootlogin|passwordauthentication) ' || true)"
[[ -n "$effective" ]] && log_info "生效配置: $(echo "$effective" | tr '\n' ' ')"

if ! grep -qi '^permitrootlogin yes' <<<"$effective" \
   && [[ "$ROOT_LOGIN" == "yes" ]]; then
    log_warn "PermitRootLogin 未按预期生效，检查 /etc/ssh/sshd_config.d/ 下其他配置"
fi

# 提醒：root 密码被锁定时，仅密钥可登录
pass_state="$(passwd -S root 2>/dev/null | awk '{print $2}' || true)"
if [[ "$pass_state" == "L" ]]; then
    log_warn "root 密码处于锁定状态，密码登录不可用；请设置密码或配置 root 的 authorized_keys"
fi
if [[ ! -s /root/.ssh/authorized_keys && "$PASSWORD_AUTH" == "no" ]]; then
    log_warn "PasswordAuthentication=no 且 root 无 authorized_keys，将无法通过 SSH 登录 root"
fi

log_info "root SSH 配置完成（PermitRootLogin=$ROOT_LOGIN）"
