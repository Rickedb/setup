#!/bin/bash

# Development Tools Installation Script for Debian
# Installs programming languages, CLI tools, and development utilities

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
# Development Languages
# ========================================
echo_info "Installing Rust..."
if ! command -v rustc &> /dev/null; then
    sudo -u $SUDO_USER curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u $SUDO_USER sh -s -- -y
else
    echo_info "Rust already installed"
fi

echo_info "Installing Ruby..."
apt install -y ruby-full

echo_info "Installing Python..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-gobject \
    python-is-python3

echo_info "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

echo_info "Installing .NET SDK..."
wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
apt update
apt install -y dotnet-sdk-9.0

# ========================================
# CLI Tools & TUI Applications
# ========================================
echo_info "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
apt install -y gh

echo_info "Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo_info "Installing Lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz

echo_info "Installing Lazydocker..."
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

echo_info "Installing Zoxide..."
sudo -u $SUDO_USER curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sudo -u $SUDO_USER bash

# ========================================
# VS Code
# ========================================
echo_info "Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
rm -f packages.microsoft.gpg
apt update
apt install -y code

echo_info "Development tools installation complete!"
echo_info ""
echo_info "Installed:"
echo_info "  - Languages: Rust, Ruby, Python 3, Node.js, .NET 9"
echo_info "  - Tools: GitHub CLI, Starship, Lazygit, Lazydocker, Zoxide"
echo_info "  - Editor: VS Code"
echo_info ""
echo_info "You may need to restart your shell or log out/in for changes to take effect."
