#!/bin/bash

# Apply the CachyOS desktop configuration from this repo to the current user.
# Run as your normal user (not with sudo); it asks for sudo only to install
# missing packages. Overwritten files are backed up first.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

if [ "$EUID" -eq 0 ]; then
    echo_warn "Run this as your normal user, not root."
    exit 1
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP="$HOME/.local/state/setup-backups/$(date +%Y%m%d-%H%M%S)"

# Copy $1 to $2, saving any file it replaces under $BACKUP/$3
deploy() {
    local src="$1" dest="$2" name="$3"
    mkdir -p "$(dirname "$dest")"
    rsync -a --backup --backup-dir="$BACKUP/$name" "$src" "$dest"
}

# ========================================
# Packages
# ========================================
PACKAGES=(fcitx5 fcitx5-gtk fcitx5-qt rsync)
MISSING=()
for pkg in "${PACKAGES[@]}"; do
    pacman -Q "$pkg" &>/dev/null || MISSING+=("$pkg")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo_info "Installing: ${MISSING[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
fi

# ========================================
# Hyprland
# ========================================
echo_info "Applying Hyprland config..."
deploy "$SRC/hyprland/" "$CONFIG/hypr/" hypr

# ========================================
# Input method (ç with ' + c) and XCompose
# ========================================
echo_info "Applying XCompose and fcitx5 config..."
deploy "$SRC/XCompose" "$HOME/.XCompose" home
deploy "$SRC/environment.d/" "$CONFIG/environment.d/" environment.d

# fcitx5 rewrites its config on exit, so stop it before copying
systemctl --user stop fcitx5.service 2>/dev/null || true
pkill -x fcitx5 2>/dev/null || true
deploy "$SRC/fcitx5/" "$CONFIG/fcitx5/" fcitx5

deploy "$SRC/systemd/fcitx5.service" "$CONFIG/systemd/user/fcitx5.service" systemd
systemctl --user daemon-reload
systemctl --user enable fcitx5.service
if [ -n "$WAYLAND_DISPLAY" ]; then
    systemctl --user import-environment WAYLAND_DISPLAY DISPLAY 2>/dev/null || true
    systemctl --user restart fcitx5.service
fi

# ========================================
# App flags (Wayland input method support)
# ========================================
echo_info "Applying Brave and VS Code flags..."
deploy "$SRC/brave-flags.conf" "$CONFIG/brave-flags.conf" config
deploy "$SRC/code-insiders-flags.conf" "$CONFIG/code-insiders-flags.conf" config

# ========================================
# Reload
# ========================================
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl reload >/dev/null
    sleep 1
    ERRORS="$(hyprctl configerrors)"
    if [ -n "$(echo "$ERRORS" | tr -d '[:space:]')" ]; then
        echo_warn "Hyprland config errors:"
        echo "$ERRORS"
    else
        echo_info "Hyprland reloaded with no errors"
    fi
fi

[ -d "$BACKUP" ] && echo_info "Replaced files backed up to $BACKUP"
echo_warn "Log out and back in so the input method environment reaches all apps."
