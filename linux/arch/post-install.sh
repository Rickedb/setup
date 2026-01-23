#!/bin/bash

# Post-installation configuration script for Arch Linux
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

# Add .dotnet tools to PATH if not present
if ! grep -q ".dotnet/tools" "$USER_HOME/.bashrc"; then
    echo 'export PATH="$HOME/.dotnet/tools:$PATH"' >> "$USER_HOME/.bashrc"
    echo_info "Added .NET tools to PATH"
fi

# Add SSH agent configuration if not present
if ! grep -q "SSH_AUTH_SOCK" "$USER_HOME/.bashrc"; then
    cat >> "$USER_HOME/.bashrc" << 'EOF'

# SSH Agent configuration
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
EOF
    echo_info "Added SSH agent auto-start to .bashrc"
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
# SSH Configuration
# ========================================
echo_info "Enabling SSH server..."
systemctl enable sshd
echo_info "SSH server enabled. To allow SSH through firewall, it's already configured in UFW."

# ========================================
# Keyboard Layout Configuration
# ========================================
echo_info "Configuring keyboard layout..."
# Set US International keyboard layout
localectl set-x11-keymap us intl
echo_info "Keyboard layout set to US International"

# ========================================
# GDM Display Manager
# ========================================
echo_info "Enabling GDM display manager..."
systemctl enable gdm
echo_info "GDM enabled - you'll have a graphical login after reboot"

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
    # Don't start them here - they'll start on login
    echo_info "Enabled Pipewire services for $USERNAME"
fi

# ========================================
# Default Audio Device (wpctl)
# ========================================
echo_info "Audio configuration..."
echo_warn "After login, you can manage audio devices with:"
echo_warn "  wpctl status              # List audio devices"
echo_warn "  wpctl set-default [ID]    # Set default device"
echo_warn "  wpctl set-volume [ID] 5%+ # Adjust volume"

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
# Hyprland Configuration
# ========================================
echo_info "Setting up Hyprland configuration..."
if [ -d "hyprland" ]; then
    mkdir -p "$USER_HOME/.config/hypr"
    cp -r hyprland/* "$USER_HOME/.config/hypr/"
    chown -R $USERNAME:$USERNAME "$USER_HOME/.config/hypr"
    echo_info "Copied Hyprland configuration to $USER_HOME/.config/hypr"
    echo_warn "Review and customize Hyprland keybindings in ~/.config/hypr/bindings.conf"
else
    echo_warn "Hyprland config directory not found. Copy manually from debian/hyprland/"
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
pacman -Sc --noconfirm
yay -Sc --noconfirm

echo_info "Post-installation configuration complete!"
echo_warn ""
echo_warn "IMPORTANT: Please reboot your system for all changes to take effect."
echo_warn ""
echo_warn "After reboot, you may want to:"
echo_warn "  1. Configure Git credentials (git config --global user.name/user.email)"
echo_warn "  2. Set up SSH keys (ssh-keygen -t ed25519, eval \"\$(ssh-agent -s)\", ssh-add ~/.ssh/id_ed25519)"
echo_warn "  3. Install GNOME extensions from https://extensions.gnome.org/"
echo_warn "  4. Configure Neovim by running: sudo ./install-neovim.sh"
echo_warn "  5. Install dev tools by running: sudo ./install-dev-tools.sh"
echo_warn "  6. Restore any dotfiles from backup"
echo_warn "  7. Configure audio device: wpctl status && wpctl set-default [ID]"
echo_warn "  8. Choose session at login: GNOME (Wayland) or Hyprland"
echo_warn ""
