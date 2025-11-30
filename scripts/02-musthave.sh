#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-utils.sh"

check_root

log ">>> Starting Phase 2: Essential (Must-have) Software & Drivers"

# ------------------------------------------------------------------------------
# 1. Btrfs & Snapper Configuration
# ------------------------------------------------------------------------------
log "Step 1/6: Checking filesystem and Snapper configuration..."

# Check if root is Btrfs
ROOT_FSTYPE=$(findmnt -n -o FSTYPE /)

if [ "$ROOT_FSTYPE" == "btrfs" ]; then
    log "-> Btrfs filesystem detected. Installing Snapper tools..."
    pacman -S --noconfirm --needed snapper snap-pac btrfs-assistant > /dev/null 2>&1
    success "Snapper, snap-pac, and btrfs-assistant installed."

    # Check for GRUB
    if [ -d "/boot/grub" ] || [ -f "/etc/default/grub" ]; then
        log "-> GRUB detected. Configuring grub-btrfs snapshot integration..."
        pacman -S --noconfirm --needed grub-btrfs inotify-tools > /dev/null 2>&1
        
        # Enable the daemon to watch for new snapshots
        systemctl enable --now grub-btrfsd > /dev/null 2>&1
        success "grub-btrfs installed and daemon enabled."

        # Configure Overlayfs in mkinitcpio
        log "-> Configuring mkinitcpio for read-only snapshot booting (overlayfs)..."
        if grep -q "grub-btrfs-overlayfs" /etc/mkinitcpio.conf; then
            log "-> grub-btrfs-overlayfs hook already exists. Skipping."
        else
            # Append the hook before the closing parenthesis
            sed -i 's/^HOOKS=(\(.*\))/HOOKS=(\1 grub-btrfs-overlayfs)/' /etc/mkinitcpio.conf
            log "-> Added grub-btrfs-overlayfs to HOOKS."
            
            log "-> Regenerating initramfs..."
            mkinitcpio -P > /dev/null 2>&1
            success "Initramfs regenerated."
        fi

        # Regenerate GRUB config
        log "-> Regenerating GRUB configuration..."
        # Detect where grub.cfg is located (User specified /efi/grub/grub.cfg in wiki)
        if [ -f "/efi/grub/grub.cfg" ]; then
            grub-mkconfig -o /efi/grub/grub.cfg > /dev/null 2>&1
            success "Updated /efi/grub/grub.cfg"
        elif [ -f "/boot/grub/grub.cfg" ]; then
            grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
            success "Updated /boot/grub/grub.cfg"
        else
            warn "Could not find grub.cfg at /efi/grub/ or /boot/grub/. Please update GRUB manually."
        fi
    else
        log "-> GRUB not detected or not standard. Skipping grub-btrfs setup."
    fi
else
    log "-> Root filesystem is not Btrfs ($ROOT_FSTYPE). Skipping Snapper setup."
fi

# ------------------------------------------------------------------------------
# 2. Audio & Video Firmware/Services
# ------------------------------------------------------------------------------
log "Step 2/6: Installing Audio/Video Firmware and Pipewire..."

# Install Firmware
log "-> Installing firmware..."
pacman -S --noconfirm --needed sof-firmware alsa-ucm-conf alsa-firmware > /dev/null 2>&1

# Install Pipewire and Pavucontrol
log "-> Installing Pipewire components and GUI..."
pacman -S --noconfirm --needed pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol > /dev/null 2>&1

# Enable services globally (for all users)
log "-> Enabling Pipewire services globally..."
systemctl --global enable pipewire pipewire-pulse wireplumber > /dev/null 2>&1
success "Audio setup complete."

# ------------------------------------------------------------------------------
# 3. Input Method (Fcitx5 + Rime + Ice Pinyin)
# ------------------------------------------------------------------------------
log "Step 3/6: Installing Fcitx5 and Rime (Ice Pinyin)..."

# Install packages
pacman -S --noconfirm --needed fcitx5-im fcitx5-rime rime-ice-pinyin-git fcitx5-mozc > /dev/null 2>&1

# Configure Rime in /etc/skel
log "-> Configuring Rime defaults (Ice Pinyin) in /etc/skel..."
target_dir="/etc/skel/.local/share/fcitx5/rime"
mkdir -p "$target_dir"

cat <<EOT > "$target_dir/default.custom.yaml"
patch:
  # Set Rime Ice as default
  __include: rime_ice_suggestion:/
EOT

success "Fcitx5 installed and default config prepared."

# ------------------------------------------------------------------------------
# 4. Bluetooth
# ------------------------------------------------------------------------------
log "Step 4/6: Installing and enabling Bluetooth..."

pacman -S --noconfirm --needed bluez blueman > /dev/null 2>&1
systemctl enable --now bluetooth > /dev/null 2>&1
success "Bluetooth enabled."

# ------------------------------------------------------------------------------
# 5. Power Management
# ------------------------------------------------------------------------------
log "Step 5/6: Installing Power Profiles Daemon..."

pacman -S --noconfirm --needed power-profiles-daemon > /dev/null 2>&1
systemctl enable --now power-profiles-daemon > /dev/null 2>&1
success "Power profiles daemon enabled."

# ------------------------------------------------------------------------------
# 6. Fastfetch
# ------------------------------------------------------------------------------
log "Step 6/6: Installing Fastfetch..."

pacman -S --noconfirm --needed fastfetch > /dev/null 2>&1
success "Fastfetch installed."

log ">>> Phase 2 (Must-have) completed."