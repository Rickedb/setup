#!/bin/bash

# Development Tools Installation Script for Arch Linux
# Installs programming languages and development utilities

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

echo_info "Installing development tools and languages..."

# ========================================
# Programming Languages
# ========================================
echo_info "Installing Rust..."
pacman -S --needed --noconfirm rust

echo_info "Installing Ruby..."
pacman -S --needed --noconfirm ruby

echo_info "Installing Python..."
pacman -S --needed --noconfirm \
    python \
    python-pip \
    python-gobject \
    python-build \
    python-installer \
    python-poetry-core \
    python-hatchling

echo_info "Installing Node.js..."
pacman -S --needed --noconfirm nodejs npm

echo_info "Installing Deno..."
pacman -S --needed --noconfirm deno

echo_info "Installing .NET SDK..."
pacman -S --needed --noconfirm \
    dotnet-sdk \
    dotnet-runtime-9.0

# ========================================
# CLI Development Tools
# ========================================
echo_info "Installing GitHub CLI..."
pacman -S --needed --noconfirm github-cli

# ========================================
# Additional Tools from AUR
# ========================================
echo_info "Installing additional development tools..."
sudo -u $SUDO_USER yay -S --needed --noconfirm \
    mise

echo_info "Development tools installation complete!"
echo_info ""
echo_info "Installed:"
echo_info "  - Languages: Rust, Ruby, Python, Node.js, Deno, .NET 9"
echo_info "  - Tools: GitHub CLI, mise"
echo_info "  - Note: lazygit, lazydocker, starship, zoxide already in main install"
echo_info ""
echo_info "You may need to restart your shell or log out/in for changes to take effect."
