#!/bin/bash

# Post-installation configuration script for Debian
# Run this after the main install.sh completes

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

USER_HOME=$(eval echo ~${SUDO_USER})
USERNAME=${SUDO_USER}

echo_info "Running post-installation configuration..."

# ========================================
# Shell Configuration
# ========================================
echo_info "Configuring shell..."

# Add Starship to bashrc if not present
if ! grep -q "starship init" "$USER_HOME/.bashrc"; then
    echo 'eval "$(starship init bash)"' >> "$USER_HOME/.bashrc"
    echo_info "Added Starship to .bashrc"
fi

# Add Zoxide to bashrc if not present
if ! grep -q "zoxide init" "$USER_HOME/.bashrc"; then
    echo 'eval "$(zoxide init bash)"' >> "$USER_HOME/.bashrc"
    echo_info "Added Zoxide to .bashrc"
fi

# Add cargo to PATH if not present
if ! grep -q ".cargo/bin" "$USER_HOME/.bashrc"; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$USER_HOME/.bashrc"
    echo_info "Added Rust cargo to PATH"
fi

# ========================================
# Git Configuration
# ========================================
echo_info "Setting up Git..."
if [ ! -f "$USER_HOME/.gitconfig" ]; then
    echo_warn "Please configure Git with your details:"
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your.email@example.com\""
fi

# ========================================
# Docker Configuration
# ========================================
echo_info "Configuring Docker..."
if [ -n "$USERNAME" ]; then
    usermod -aG docker $USERNAME
    echo_info "Added $USERNAME to docker group"
    echo_warn "Please log out and back in for docker group changes to take effect"
fi

# ========================================
# Systemd Services
# ========================================
echo_info "Enabling system services..."

# Enable and start Bluetooth
systemctl enable bluetooth
systemctl start bluetooth

# Enable and start CUPS
systemctl enable cups
systemctl start cups

# Enable and start Avahi
systemctl enable avahi-daemon
systemctl start avahi-daemon

# Enable and start NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager

# ========================================
# UFW Firewall
# ========================================
echo_info "Configuring UFW firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
systemctl enable ufw

# ========================================
# Pipewire User Services
# ========================================
echo_info "Configuring Pipewire for user..."
if [ -n "$USERNAME" ]; then
    sudo -u $USERNAME systemctl --user enable pipewire pipewire-pulse wireplumber
    echo_info "Enabled Pipewire services for $USERNAME"
fi

# ========================================
# Flatpak Configuration
# ========================================
echo_info "Updating Flatpak repositories..."
flatpak update -y

# ========================================
# Font Cache
# ========================================
echo_info "Rebuilding font cache..."
fc-cache -f -v

# ========================================
# Update Locate Database
# ========================================
echo_info "Updating locate database..."
updatedb

# ========================================
# GNOME Settings
# ========================================
echo_info "Applying GNOME settings..."
if [ -n "$USERNAME" ]; then
    # Enable fractional scaling
    sudo -u $USERNAME dconf write /org/gnome/mutter/experimental-features "['scale-monitor-framebuffer']"
    
    # Set dark theme
    sudo -u $USERNAME gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    
    # Enable minimize/maximize buttons
    sudo -u $USERNAME gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    
    # Set favorite apps
    sudo -u $USERNAME gsettings set org.gnome.shell favorite-apps "['brave-browser.desktop', 'org.gnome.Console.desktop', 'org.gnome.Nautilus.desktop', 'code.desktop']"
    
    echo_info "Applied GNOME settings for $USERNAME"
fi

# ========================================
# Create User Directories
# ========================================
echo_info "Setting up user directories..."
if [ -n "$USERNAME" ]; then
    sudo -u $USERNAME xdg-user-dirs-update
fi

# ========================================
# Neovim Configuration
# ========================================
echo_info "Setting up Neovim directories..."
mkdir -p "$USER_HOME/.config/nvim"
chown -R $USERNAME:$USERNAME "$USER_HOME/.config/nvim"

# ========================================
# Cleanup
# ========================================
echo_info "Cleaning up..."
apt autoremove -y
apt autoclean -y

echo_info "Post-installation configuration complete!"
echo_warn ""
echo_warn "IMPORTANT: Please reboot your system for all changes to take effect."
echo_warn ""
echo_warn "After reboot, you may want to:"
echo_warn "  1. Configure Git credentials"
echo_warn "  2. Install GNOME extensions from https://extensions.gnome.org/"
echo_warn "  3. Configure Neovim plugins"
echo_warn "  4. Set up SSH keys"
echo_warn "  5. Restore any dotfiles from backup"
echo_warn ""
echo_warn "If you need Hyprland, follow the manual installation guide in README.md"
