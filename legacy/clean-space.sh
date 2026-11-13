#!/usr/bin/env bash
# =============================================================================
# Kali Linux 精简空间脚本 - 强迫症友好版
# 作者: 自动化部署
# 用途: 安装/配置 Kali 时执行一次性空间清理和优化
# 警告: 会删除旧内核、缓存、日志等，请确认无重要数据后再运行
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${BLUE}▶ $1${NC}"; }

# 获取清理前空间
get_space() {
    df -h / | awk 'NR==2 {print $3}'
}

SPACE_BEFORE=$(get_space)
log_info "当前根分区已用空间: $SPACE_BEFORE"

# =============================================================================
# 1. 日志系统瘦身 (用户明确要求)
# =============================================================================
log_step "1. 日志系统瘦身"

# 限制 journal 大小为 200M
sudo journalctl --vacuum-size=200M
# 保留最近 3 天的日志
sudo journalctl --vacuum-time=3d
# 限制单个日志文件 50M
sudo sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=200M/' /etc/systemd/journald.conf
sudo sed -i 's/^#SystemMaxFileSize=.*/SystemMaxFileSize=50M/' /etc/systemd/journald.conf
sudo sed -i 's/^#MaxRetentionSec=.*/MaxRetentionSec=3day/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
log_info "journald 已限制为 200M，保留 3 天"

# 清理 rsyslog 旧日志 (如果存在)
if [ -d /var/log ]; then
    sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
    sudo find /var/log -type f -name "*.old" -delete 2>/dev/null || true
    sudo find /var/log -type f -name "*.1" -delete 2>/dev/null || true
    # 清空大日志文件但保留文件本身
    sudo find /var/log -type f -size +10M -exec sh -c '> "$1"' _ {} \; 2>/dev/null || true
    log_info "传统日志文件已清理"
fi

# =============================================================================
# 2. APT 缓存清理
# =============================================================================
log_step "2. APT 缓存清理"

sudo apt-get clean
sudo apt-get autoclean
sudo rm -rf /var/cache/apt/archives/*.deb
sudo rm -rf /var/cache/apt/archives/partial/*
log_info "APT 缓存已清理"

# =============================================================================
# 3. 删除旧内核 (保留当前运行的内核 + 最新一个备用)
# =============================================================================
log_step "3. 旧内核清理"

CURRENT_KERNEL=$(uname -r)
log_info "当前运行内核: $CURRENT_KERNEL"

# 获取所有已安装内核镜像，按版本排序
KERNELS=$(dpkg -l 'linux-image-*' | grep '^ii' | awk '{print $2}' | sort -V)
KERNEL_COUNT=$(echo "$KERNELS" | wc -l)

if [ "$KERNEL_COUNT" -gt 2 ]; then
    # 保留当前内核和最新的一个
    KERNELS_TO_REMOVE=$(echo "$KERNELS" | grep -v "$CURRENT_KERNEL" | head -n -1)
    for kernel in $KERNELS_TO_REMOVE; do
        log_warn "准备移除旧内核: $kernel"
        sudo apt-get remove --purge -y "$kernel" || true
        # 同时移除对应 header
        header_pkg=$(echo "$kernel" | sed 's/linux-image-/linux-headers-/')
        if dpkg -l "$header_pkg" >/dev/null 2>&1; then
            sudo apt-get remove --purge -y "$header_pkg" || true
        fi
    done
    sudo update-grub
    log_info "旧内核已清理"
else
    log_info "内核数量 ≤2，跳过清理"
fi

# =============================================================================
# 4. 清理残留依赖和配置
# =============================================================================
log_step "4. 残留包清理"

sudo apt-get autoremove --purge -y
sudo apt-get remove --purge $(dpkg -l | grep '^rc' | awk '{print $2}') -y 2>/dev/null || true
log_info "残留包已清理"

# =============================================================================
# 5. 清理临时文件和缓存
# =============================================================================
log_step "5. 临时文件清理"

# 系统临时文件
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true

# 用户缓存
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
rm -rf ~/.cache/pip/* 2>/dev/null || true
rm -rf ~/.cache/mozilla/* 2>/dev/null || true
rm -rf ~/.cache/chromium/* 2>/dev/null || true

# 清理崩溃报告
sudo rm -rf /var/crash/* 2>/dev/null || true

# 清理旧备份
sudo rm -rf /var/backups/*.gz 2>/dev/null || true

log_info "临时文件已清理"

# =============================================================================
# 6. 清理 Docker (如果安装了)
# =============================================================================
log_step "6. Docker 清理 (如已安装)"

if command -v docker &> /dev/null; then
    docker system prune -af --volumes 2>/dev/null || true
    log_info "Docker 镜像/容器/卷已清理"
else
    log_info "Docker 未安装，跳过"
fi

# =============================================================================
# 7. 清理 Snap/Flatpak (Kali 通常不用，但以防万一)
# =============================================================================
log_step "7. Snap/Flatpak 清理"

if command -v snap &> /dev/null; then
    sudo snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
    done
    log_info "Snap 旧版本已清理"
fi

if command -v flatpak &> /dev/null; then
    flatpak uninstall --unused -y 2>/dev/null || true
    log_info "Flatpak 未使用运行时已清理"
fi

# =============================================================================
# 8. 清理字体缓存
# =============================================================================
log_step "8. 字体缓存清理"

sudo fc-cache -f -v >/dev/null 2>&1 || true
log_info "字体缓存已重建"

# =============================================================================
# 9. 清理 locales (可选，可释放几十MB)
# =============================================================================
log_step "9. 本地化文件精简"

# 如果你只需要中文和英文，可以取消下面注释
# sudo apt-get install localepurge -y
# sudo localepurge
# log_info "多余 locale 已清理"
log_warn "locale 清理已跳过 (如需执行请取消脚本注释)"

# =============================================================================
# 10. 清理 man/info 文档 (可选，极度强迫症)
# =============================================================================
log_step "10. 文档清理 (可选)"

# 如果你从不需要本地文档，取消下面注释
# sudo rm -rf /usr/share/man/* /usr/share/info/* /usr/share/doc/*
# log_info "文档已清理"
log_warn "文档清理已跳过 (如需执行请取消脚本注释)"

# =============================================================================
# 11. 清理旧日志轮转状态
# =============================================================================
log_step "11. logrotate 状态清理"

sudo rm -f /var/lib/logrotate/status.old 2>/dev/null || true
log_info "logrotate 旧状态已清理"

# =============================================================================
# 12. 最终 APT 清理
# =============================================================================
log_step "12. 最终 APT 清理"

sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove --purge -y
log_info "APT 最终清理完成"

# =============================================================================
# 结果报告
# =============================================================================
SPACE_AFTER=$(get_space)
log_info "清理前已用空间: $SPACE_BEFORE"
log_info "清理后已用空间: $SPACE_AFTER"
log_info "脚本执行完毕！建议重启以释放旧内核占用的空间。"
