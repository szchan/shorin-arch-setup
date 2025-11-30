#!/bin/bash

# 获取当前脚本所在目录，以便引用 utils
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-utils.sh"

# 检查权限
check_root

log ">>> 开始执行阶段 1：基础系统环境配置"

# ------------------------------------------------------------------------------
# 1. 设置全局默认编辑器
# ------------------------------------------------------------------------------
log "步骤 1/5: 配置全局默认编辑器..."

TARGET_EDITOR="vim"

if command -v nvim &> /dev/null; then
    TARGET_EDITOR="nvim"
    log "-> 检测到 Neovim"
elif command -v nano &> /dev/null; then
    TARGET_EDITOR="nano"
    log "-> 检测到 Nano"
else
    log "-> 未检测到 Nvim 或 Nano，正在安装 Vim..."
    if ! command -v vim &> /dev/null; then
        pacman -S --noconfirm vim > /dev/null 2>&1
    fi
fi

if grep -q "^EDITOR=" /etc/environment; then
    sed -i "s/^EDITOR=.*/EDITOR=${TARGET_EDITOR}/" /etc/environment
else
    echo "EDITOR=${TARGET_EDITOR}" >> /etc/environment
fi
success "全局编辑器已设置为: ${TARGET_EDITOR}"

# ------------------------------------------------------------------------------
# 2. 开启 32 位源
# ------------------------------------------------------------------------------
log "步骤 2/5: 检查 32 位源 [multilib]..."

if grep -q "^\[multilib\]" /etc/pacman.conf; then
    success "[multilib] 已经开启。"
else
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    log "-> 已取消注释，正在刷新数据库..."
    pacman -Sy > /dev/null 2>&1
    success "[multilib] 已开启并刷新。"
fi

# ------------------------------------------------------------------------------
# 3. 安装基础字体
# ------------------------------------------------------------------------------
log "步骤 3/5: 安装基础字体..."
pacman -S --noconfirm --needed wqy-zenhei noto-fonts noto-fonts-emoji > /dev/null 2>&1
success "字体安装完成。"

# ------------------------------------------------------------------------------
# 4. archlinuxcn 源
# ------------------------------------------------------------------------------
log "步骤 4/5: 配置 archlinuxcn 源..."

if grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
    success "archlinuxcn 源已存在。"
else
    cat <<EOT >> /etc/pacman.conf

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.hit.edu.cn/archlinuxcn/\$arch
Server = https://repo.huaweicloud.com/archlinuxcn/\$arch
EOT
    log "-> 已写入配置文件。"
fi

log "-> 安装 archlinuxcn-keyring..."
pacman -Sy --noconfirm archlinuxcn-keyring > /dev/null 2>&1
success "archlinuxcn 配置完成。"

# ------------------------------------------------------------------------------
# 5. 安装 AUR 助手
# ------------------------------------------------------------------------------
log "步骤 5/5: 安装 yay 和 paru..."
pacman -S --noconfirm --needed yay paru > /dev/null 2>&1
success "AUR 助手安装完成。"

log ">>> 阶段 1 完成。"