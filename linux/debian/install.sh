#!/bin/bash

# Debian Installation Script
# Generated based on Arch Linux configuration
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

echo_info "Starting Debian system configuration..."

# Update system
echo_info "Updating system..."
apt update
apt upgrade -y

# Add contrib and non-free repositories
echo_info "Enabling contrib and non-free repositories..."
sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list

# Add Debian Sid (trixie) repository for Hyprland
echo_info "Adding Debian Sid repository for Hyprland..."
echo 'deb http://deb.debian.org/debian/ sid main contrib non-free non-free-firmware' > /etc/apt/sources.list.d/sid.list
echo 'APT::Default-Release "stable";' > /etc/apt/apt.conf.d/99defaultrelease

apt update

# ========================================
# Base System & Development Tools
# ========================================
echo_info "Installing base development tools..."
apt install -y \
    build-essential \
    cmake \
    clang \
    llvm \
    pkg-config \
    git \
    curl \
    wget \
    unzip \
    gnupg \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    bash-completion \
    man-db \
    less \
    tree \
    htop \
    btop \
    neovim \
    vim \
    tmux

# ========================================
# System Utilities
# ========================================
echo_info "Installing system utilities..."
apt install -y \
    brightnessctl \
    fastfetch \
    bat \
    fd-find \
    ripgrep \
    fzf \
    jq \
    yq \
    expat \
    xdg-utils \
    xdg-terminal-exec \
    inetutils-tools \
    whois \
    plocate \
    inxi \
    dust \
    eza \
    tldr \
    xmlstarlet

# Create symlinks for Debian naming differences
ln -sf /usr/bin/batcat /usr/local/bin/bat || true
ln -sf /usr/bin/fdfind /usr/local/bin/fd || true

# ========================================
# Filesystem Tools
# ========================================
echo_info "Installing filesystem tools..."
apt install -y \
    btrfs-progs \
    dosfstools \
    exfatprogs \
    ntfs-3g \
    efibootmgr

# ========================================
# Wayland & Display Server
# ========================================
echo_info "Installing Wayland and related packages..."
apt install -y \
    wayland-protocols \
    libwayland-dev \
    wlroots \
    egl-wayland \
    grim \
    slurp \
    wl-clipboard \
    swayidle \
    swaybg \
    mako-notifier \
    xdg-desktop-portal-wlr

# ========================================
# Audio & Video
# ========================================
echo_info "Installing audio and video packages..."
apt install -y \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    pipewire-audio-client-libraries \
    wireplumber \
    pavucontrol \
    pamixer \
    playerctl \
    pulseaudio-utils \
    mpv \
    ffmpegthumbnailer \
    imagemagick \
    vlc

# ========================================
# GNOME Desktop Environment
# ========================================
echo_info "Installing GNOME desktop environment..."
apt install -y \
    gnome-shell \
    gnome-session \
    gnome-control-center \
    gnome-settings-daemon \
    gnome-terminal \
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
    gnome-text-editor \
    gnome-console \
    nautilus \
    evince \
    eog \
    file-roller \
    baobab \
    simple-scan \
    cheese \
    totem \
    dconf-editor \
    polkit-gnome \
    gvfs \
    gvfs-backends

# ========================================
# Display Manager
# ========================================
echo_info "Installing display manager..."
apt install -y gdm3

# ========================================
# Networking
# ========================================
echo_info "Installing networking tools..."
apt install -y \
    network-manager \
    network-manager-gnome \
    iwd \
    wireless-tools \
    wpasupplicant \
    avahi-daemon \
    nss-mdns \
    ufw \
    openssh-client \
    openssh-server \
    freerdp2-x11

# Enable UFW
systemctl enable ufw
ufw enable

# ========================================
# Bluetooth
# ========================================
echo_info "Installing bluetooth support..."
apt install -y \
    bluez \
    bluez-tools \
    blueman

# ========================================
# Printing
# ========================================
echo_info "Installing printing support..."
apt install -y \
    cups \
    cups-filters \
    cups-pdf \
    cups-browsed \
    system-config-printer

# ========================================
# Fonts
# ========================================
echo_info "Installing fonts..."
apt install -y \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-liberation \
    fonts-dejavu \
    fonts-font-awesome \
    fontconfig

# ========================================
# Docker
# ========================================
echo_info "Installing Docker..."
apt install -y \
    docker.io \
    docker-compose

systemctl enable docker
usermod -aG docker $SUDO_USER || true

# ========================================
# GUI Applications
# ========================================
echo_info "Installing GUI applications..."

# Brave Browser
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
apt update
apt install -y brave-browser

# LibreOffice
apt install -y libreoffice

# GIMP
apt install -y gimp

# Kdenlive
apt install -y kdenlive

# OBS Studio
apt install -y obs-studio

# VLC
apt install -y vlc

# Remmina
apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc

# ========================================
# Hyprland (from Debian Sid repository)
# ========================================
echo_info "Installing Hyprland and related utilities..."
apt install -y -t sid \
    hyprland \
    xdg-desktop-portal-hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    hyprpicker

# ========================================
# Flatpak (for apps not in Debian repos)
# ========================================
echo_info "Installing Flatpak..."
apt install -y flatpak
apt install -y gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo_info "Installing applications via Flatpak..."
# Obsidian
flatpak install -y flathub md.obsidian.Obsidian

# ========================================
# Firmware & Microcode
# ========================================
echo_info "Installing firmware and microcode..."
apt install -y \
    firmware-linux \
    firmware-linux-nonfree \
    intel-microcode

# ========================================
# Snapper (BTRFS snapshots)
# ========================================
echo_info "Installing Snapper..."
apt install -y snapper

# ========================================
# Power Management
# ========================================
echo_info "Installing power management tools..."
apt install -y \
    power-profiles-daemon \
    tlp \
    tlp-rdw

# ========================================
# Virtualization
# ========================================
echo_info "Installing virtualization tools..."
apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    gnome-boxes

# ========================================
# Additional Libraries
# ========================================
echo_info "Installing additional libraries..."
apt install -y \
    libpq-dev \
    libmariadb-dev \
    libyaml-dev \
    libqalculate-dev \
    libva-drm2 \
    libva-x11-2

# ========================================
# Cleanup
# ========================================
echo_info "Cleaning up..."
apt autoremove -y
apt autoclean -y

echo_info "Installation complete!"
echo_warn "Please reboot your system for all changes to take effect."
echo_warn ""
echo_warn "Manual installation required for:"
echo_warn "  - NVIDIA drivers (if needed)"
echo_warn "  - Ghostty terminal"
echo_warn "  - Some AUR-specific packages"
echo_warn ""
echo_warn "Flatpak alternatives installed for:"
echo_warn "  - Obsidian"
