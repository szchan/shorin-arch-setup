#!/bin/bash

# Get script directory to source utils
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-utils.sh"

check_root

log ">>> Starting Phase 1: Base System Configuration"

# ------------------------------------------------------------------------------
# 1. Set Global Default Editor
# ------------------------------------------------------------------------------
log "Step 1/5: Configuring global default editor..."

TARGET_EDITOR="vim"

if command -v nvim &> /dev/null; then
    TARGET_EDITOR="nvim"
    log "-> Neovim detected."
elif command -v nano &> /dev/null; then
    TARGET_EDITOR="nano"
    log "-> Nano detected."
else
    log "-> Neovim or Nano not found. Installing Vim..."
    if ! command -v vim &> /dev/null; then
        pacman -S --noconfirm vim > /dev/null 2>&1
    fi
fi

# Modify /etc/environment
if grep -q "^EDITOR=" /etc/environment; then
    sed -i "s/^EDITOR=.*/EDITOR=${TARGET_EDITOR}/" /etc/environment
else
    echo "EDITOR=${TARGET_EDITOR}" >> /etc/environment
fi
success "Global EDITOR set to: ${TARGET_EDITOR}"

# ------------------------------------------------------------------------------
# 2. Enable 32-bit (multilib) Repository
# ------------------------------------------------------------------------------
log "Step 2/5: Checking [multilib] 32-bit repository..."

if grep -q "^\[multilib\]" /etc/pacman.conf; then
    success "[multilib] is already enabled."
else
    # Uncomment [multilib] and the following Include line
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    log "-> Uncommented [multilib]. Refreshing pacman database..."
    pacman -Sy > /dev/null 2>&1
    success "[multilib] enabled and refreshed."
fi

# ------------------------------------------------------------------------------
# 3. Install Base Fonts
# ------------------------------------------------------------------------------
log "Step 3/5: Installing base fonts (wqy-zenhei, noto-fonts, emoji)..."
pacman -S --noconfirm --needed wqy-zenhei noto-fonts noto-fonts-emoji > /dev/null 2>&1
success "Base fonts installed."

# ------------------------------------------------------------------------------
# 4. Configure archlinuxcn Repository
# ------------------------------------------------------------------------------
log "Step 4/5: Configuring archlinuxcn repository..."

if grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
    success "archlinuxcn repository already exists."
else
    cat <<EOT >> /etc/pacman.conf

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.hit.edu.cn/archlinuxcn/\$arch
Server = https://repo.huaweicloud.com/archlinuxcn/\$arch
EOT
    log "-> Added mirror servers to pacman.conf."
fi

log "-> Installing archlinuxcn-keyring..."
pacman -Sy --noconfirm archlinuxcn-keyring > /dev/null 2>&1
success "archlinuxcn configured successfully."

# ------------------------------------------------------------------------------
# 5. Install AUR Helpers
# ------------------------------------------------------------------------------
log "Step 5/5: Installing AUR helpers (yay & paru)..."
pacman -S --noconfirm --needed yay paru > /dev/null 2>&1
success "yay and paru installed."

log ">>> Phase 1 completed."