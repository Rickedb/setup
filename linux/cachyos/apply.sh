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

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP="$HOME/.local/state/setup-backups/$(date +%Y%m%d-%H%M%S)"

# ========================================
# Personal values
# ========================================
# Files in the repo use {{PLACEHOLDERS}} for personal data. Fill them from
# personal.env (git-ignored, see personal.env.example) into a staging copy.
if [ ! -f "$REPO/personal.env" ]; then
    echo_warn "No personal.env found; copy personal.env.example to personal.env and fill it in."
    exit 1
fi
# shellcheck source=/dev/null
source "$REPO/personal.env"

SRC="$(mktemp -d)"
trap 'rm -rf "$SRC"' EXIT
rsync -a --exclude='personal.env*' --exclude='apply.sh' "$REPO/" "$SRC/"

while IFS= read -r -d '' file; do
    content="$(<"$file")"
    for key in $(grep -o '{{[A-Z0-9_]*}}' "$file" | sort -u | tr -d '{}'); do
        if [ "$key" = "HOME" ]; then
            value="$HOME"
        elif [ -n "${!key+x}" ]; then
            value="${!key}"
        else
            echo_warn "${file#"$SRC"/}: no value for {{$key}} in personal.env"
            continue
        fi
        content="${content//"{{$key}}"/"$value"}"
    done
    printf '%s\n' "$content" > "$file"
done < <(grep -rlZ '{{[A-Z0-9_]*}}' "$SRC")

# Copy $1 to $2, saving any file it replaces under $BACKUP/$3
deploy() {
    local src="$1" dest="$2" name="$3"
    mkdir -p "$(dirname "$dest")"
    rsync -a --backup --backup-dir="$BACKUP/$name" "$src" "$dest"
}

# ========================================
# Packages
# ========================================
# Package lists live in packages.txt (repos) and packages-aur.txt (AUR);
# ./track-packages.sh shows installed packages that are not tracked yet.
read_list() { grep -vE '^\s*(#|$)' "$1"; }

MISSING=()
while read -r pkg; do
    pacman -Q "$pkg" &>/dev/null || MISSING+=("$pkg")
done < <(read_list "$REPO/packages.txt")
if [ ${#MISSING[@]} -gt 0 ]; then
    echo_info "Installing: ${MISSING[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
fi

MISSING=()
while read -r pkg; do
    pacman -Q "$pkg" &>/dev/null || MISSING+=("$pkg")
done < <(read_list "$REPO/packages-aur.txt")
if [ ${#MISSING[@]} -gt 0 ]; then
    AUR_HELPER="$(command -v yay || command -v paru || true)"
    if [ -n "$AUR_HELPER" ]; then
        echo_info "Installing from AUR: ${MISSING[*]}"
        "$AUR_HELPER" -S --needed "${MISSING[@]}"
    else
        echo_warn "No AUR helper (yay/paru); install manually: ${MISSING[*]}"
    fi
fi

# ========================================
# Hyprland
# ========================================
echo_info "Applying Hyprland config..."
deploy "$SRC/hyprland/" "$CONFIG/hypr/" hypr

# ========================================
# Noctalia (bar config + Claude Code usage plugin)
# ========================================
# The plugin reads ~/.claude/.credentials.json, so run `claude` and log in once.
echo_info "Applying Noctalia config..."
deploy "$SRC/noctalia/" "$CONFIG/noctalia/" noctalia
if command -v noctalia &>/dev/null && pgrep -x noctalia &>/dev/null; then
    noctalia msg plugins enable jrohland/claudecode >/dev/null \
        && echo_info "Enabled Noctalia plugin jrohland/claudecode" \
        || echo_warn "Could not enable jrohland/claudecode (is the community plugin source added?)"
else
    echo_warn "Noctalia is not running; later run: noctalia msg plugins enable jrohland/claudecode"
fi

# ========================================
# mise (language runtimes and CLI tools)
# ========================================
# Only the config is deployed; install the tools yourself with `mise install`.
echo_info "Applying mise config..."
deploy "$SRC/mise/" "$CONFIG/mise/" mise

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
deploy "$SRC/systemd/ssh-add.service" "$CONFIG/systemd/user/ssh-add.service" systemd
systemctl --user daemon-reload
systemctl --user enable fcitx5.service
if [ -n "$WAYLAND_DISPLAY" ]; then
    systemctl --user import-environment WAYLAND_DISPLAY DISPLAY 2>/dev/null || true
    systemctl --user restart fcitx5.service
fi

# ========================================
# SSH agent (keys from SSH_KEYS in personal.env loaded at login)
# ========================================
# environment.d (deployed above) points SSH_AUTH_SOCK at the agent socket.
echo_info "Applying SSH agent config..."
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
deploy "$SRC/ssh/config" "$HOME/.ssh/config" ssh
chmod 600 "$HOME/.ssh/config"
systemctl --user enable ssh-agent.socket ssh-add.service
systemctl --user restart ssh-add.service \
    || echo_warn "ssh-add.service failed; check SSH_KEYS in personal.env and run: journalctl --user -u ssh-add"

# ========================================
# SSH server (sshd started at boot)
# ========================================
if ! systemctl is-enabled --quiet sshd.service || ! systemctl is-active --quiet sshd.service; then
    echo_info "Enabling sshd.service..."
    sudo systemctl enable --now sshd.service
fi

# ufw is the CachyOS firewall; allow inbound SSH (idempotent, rule is persisted)
echo_info "Allowing SSH through ufw..."
sudo ufw allow ssh

# ========================================
# App flags (Wayland input method support)
# ========================================
echo_info "Applying Brave and VS Code flags..."
deploy "$SRC/brave-flags.conf" "$CONFIG/brave-flags.conf" config
deploy "$SRC/code-insiders-flags.conf" "$CONFIG/code-insiders-flags.conf" config

# ========================================
# Remmina
# ========================================
# The repo copy has passwords and the encryption secret stripped, so only seed
# missing files; never overwrite an existing pref (its secret decrypts saved passwords).
echo_info "Seeding Remmina connections..."
mkdir -p "$CONFIG/remmina" "$HOME/.local/share/remmina"
rsync -a --ignore-existing "$SRC/remmina/remmina.pref" "$CONFIG/remmina/remmina.pref"
if ! compgen -G "$HOME/.local/share/remmina/*.remmina" >/dev/null; then
    rsync -a "$SRC/remmina/connections/" "$HOME/.local/share/remmina/"
fi

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
