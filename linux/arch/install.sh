#!/bin/bash

# Arch Linux Installation Script
# Based on current system configuration
# Date: 2026-01-22

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo_error "Please run as root or with sudo"
    exit 1
fi

echo_info "Starting Arch Linux system configuration..."

# Update system
echo_info "Updating system..."
pacman -Syu --noconfirm

# Install yay if not present
if ! command -v yay &> /dev/null; then
    echo_info "Installing yay AUR helper..."
    pacman -S --needed --noconfirm base-devel git
    cd /tmp
    sudo -u $SUDO_USER git clone https://aur.archlinux.org/yay.git
    cd yay
    sudo -u $SUDO_USER makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# ========================================
# Base System & Development Tools
# ========================================
echo_info "Installing base development tools..."
pacman -S --needed --noconfirm \
    base \
    base-devel \
    bash-completion \
    man-db \
    less \
    git \
    cmake \
    clang \
    llvm \
    neovim \
    tmux \
    tree

# ========================================
# System Utilities
# ========================================
echo_info "Installing system utilities..."
pacman -S --needed --noconfirm \
    brightnessctl \
    fastfetch \
    bat \
    fd \
    ripgrep \
    fzf \
    jq \
    yq \
    expac \
    xdg-utils \
    xdg-terminal-exec \
    inetutils \
    whois \
    plocate \
    inxi \
    dust \
    eza \
    tldr \
    xmlstarlet \
    unzip

# ========================================
# Filesystem Tools
# ========================================
echo_info "Installing filesystem tools..."
pacman -S --needed --noconfirm \
    btrfs-progs \
    dosfstools \
    exfatprogs \
    ntfs-3g \
    efibootmgr \
    snapper

# ========================================
# Wayland & Hyprland
# ========================================
echo_info "Installing Wayland and Hyprland..."
pacman -S --needed --noconfirm \
    hyprland \
    hypridle \
    hyprlock \
    hyprpicker \
    xdg-desktop-portal-hyprland \
    egl-wayland \
    grim \
    slurp \
    wl-clipboard \
    swaybg \
    mako \
    waybar

# Install Hyprland extras from AUR
sudo -u $SUDO_USER yay -S --needed --noconfirm \
    hyprsunset \
    hyprland-guiutils \
    hyprland-preview-share-picker

# ========================================
# Audio & Video
# ========================================
echo_info "Installing audio and video packages..."
pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    gst-plugin-pipewire \
    libpulse \
    pavucontrol \
    pamixer \
    playerctl \
    mpv \
    vlc \
    ffmpegthumbnailer \
    imagemagick \
    obs-studio

# ========================================
# GNOME Desktop Environment
# ========================================
echo_info "Installing GNOME desktop environment..."
pacman -S --needed --noconfirm \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-settings-daemon \
    gnome-console \
    gnome-text-editor \
    gnome-tweaks \
    gnome-keyring \
    gnome-disk-utility \
    gnome-system-monitor \
    gnome-calculator \
    gnome-calendar \
    gnome-characters \
    gnome-clocks \
    gnome-contacts \
    gnome-font-viewer \
    gnome-logs \
    gnome-maps \
    gnome-music \
    gnome-weather \
    gnome-software \
    gnome-backgrounds \
    nautilus \
    evince \
    loupe \
    file-roller \
    baobab \
    simple-scan \
    dconf-editor \
    polkit-gnome \
    gvfs-afc \
    gvfs-dnssd \
    gvfs-goa \
    gvfs-google \
    gvfs-gphoto2 \
    gvfs-mtp \
    gvfs-nfs \
    gvfs-smb

# Install additional GNOME AUR packages
sudo -u $SUDO_USER yay -S --needed --noconfirm \
    gvfs-onedrive \
    gvfs-wsdd

# ========================================
# Display Manager
# ========================================
echo_info "Installing display manager..."
pacman -S --needed --noconfirm gdm

# ========================================
# Networking
# ========================================
echo_info "Installing networking tools..."
pacman -S --needed --noconfirm \
    networkmanager \
    iwd \
    nss-mdns \
    ufw \
    openssh \
    freerdp

# Install ufw-docker from AUR
sudo -u $SUDO_USER yay -S --needed --noconfirm ufw-docker

# ========================================
# Bluetooth & Printing
# ========================================
echo_info "Installing bluetooth and printing support..."
pacman -S --needed --noconfirm \
    bluez \
    bluez-utils \
    blueman \
    cups \
    cups-filters \
    cups-pdf \
    cups-browsed \
    system-config-printer

# ========================================
# Fonts
# ========================================
echo_info "Installing fonts..."
pacman -S --needed --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    noto-fonts-extra \
    ttf-liberation \
    ttf-dejavu \
    fontconfig

# Install Nerd Fonts from AUR
sudo -u $SUDO_USER yay -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-cascadia-mono-nerd \
    woff2-font-awesome

# ========================================
# Docker & Virtualization
# ========================================
echo_info "Installing Docker and virtualization..."
pacman -S --needed --noconfirm \
    docker \
    docker-buildx \
    docker-compose \
    qemu-full \
    libvirt \
    virt-manager \
    gnome-boxes

# ========================================
# GUI Applications
# ========================================
echo_info "Installing GUI applications..."

# Install from official repos
pacman -S --needed --noconfirm \
    libreoffice-fresh \
    kdenlive \
    remmina

# Install from AUR
sudo -u $SUDO_USER yay -S --needed --noconfirm \
    brave-bin \
    visual-studio-code-bin \
    obsidian \
    spotify \
    discord \
    steam

# ========================================
# Terminal Tools (AUR)
# ========================================
echo_info "Installing terminal tools..."
sudo -u $SUDO_USER yay -S --needed --noconfirm \
    lazygit \
    lazydocker \
    zoxide \
    starship \
    atac \
    gum

# ========================================
# Power Management
# ========================================
echo_info "Installing power management tools..."
pacman -S --needed --noconfirm \
    power-profiles-daemon \
    tlp

# ========================================
# Firmware & Microcode
# ========================================
echo_info "Installing firmware and microcode..."
pacman -S --needed --noconfirm \
    linux-firmware \
    sof-firmware \
    intel-ucode

# NVIDIA drivers (if needed)
echo_warn "Skipping NVIDIA drivers. Install manually if needed:"
echo_warn "  sudo pacman -S nvidia-open-dkms nvidia-utils libva-nvidia-driver"

# ========================================
# Development Libraries
# ========================================
echo_info "Installing development libraries..."
pacman -S --needed --noconfirm \
    postgresql-libs \
    mariadb-libs \
    libyaml \
    libqalculate

# ========================================
# Bootloader & System Tools
# ========================================
echo_info "Installing bootloader and system tools..."
pacman -S --needed --noconfirm \
    linux \
    linux-headers

# Install limine if needed
# sudo -u $SUDO_USER yay -S --needed --noconfirm \
#     limine \
#     limine-mkinitcpio-hook \
#     limine-snapper-sync

# ========================================
# Enable Services
# ========================================
echo_info "Enabling system services..."
systemctl enable gdm
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable docker
systemctl enable ufw
systemctl enable sshd

# ========================================
# Cleanup
# ========================================
echo_info "Cleaning up..."
pacman -Sc --noconfirm
sudo -u $SUDO_USER yay -Sc --noconfirm

echo_info "Installation complete!"
echo_warn ""
echo_warn "Please reboot your system for all changes to take effect."
echo_warn ""
echo_warn "Additional setup:"
echo_warn "  - Run ./post-install.sh after reboot"
echo_warn "  - Run ./install-dev-tools.sh for development languages"
echo_warn "  - Run ./install-neovim.sh for Neovim configuration"
echo_warn "  - Configure NVIDIA drivers if needed"
echo_warn ""
