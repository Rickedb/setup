# Arch Linux Configuration

This configuration represents your current Arch Linux system setup, making it easy to replicate on a fresh installation.

## Installation

1. Make the script executable:
```bash
chmod +x install.sh
```

2. Run the installation script with sudo:
```bash
sudo ./install.sh
```

## What's Included

### Core System (263 packages)

| Category | Packages |
|----------|----------|
| **Base System** | base, base-devel, linux, linux-firmware, linux-headers |
| **Desktop Environment** | GNOME Shell + Hyprland dual setup |
| **Display Manager** | GDM (GNOME Display Manager) |
| **Audio** | Pipewire with PulseAudio compatibility |
| **Development** | Rust, Ruby, Python, Node.js, Deno, .NET SDK 9 |
| **Editors** | Neovim, VS Code |
| **Browsers** | Brave |
| **Terminal Tools** | bat, fd, ripgrep, eza, dust, lazygit, lazydocker, starship, zoxide |
| **Wayland Compositor** | Hyprland with hypridle, hyprlock, hyprpicker, waybar |
| **Office** | LibreOffice Fresh |
| **Graphics** | GIMP, Kdenlive, OBS Studio |
| **Communication** | Discord, Spotify, Signal, Obsidian |
| **Containers** | Docker with docker-compose |
| **Virtualization** | QEMU, libvirt, virt-manager, gnome-boxes, Vagrant |

### Optional Scripts

#### Development Tools
Run `sudo ./install-dev-tools.sh` to install:
- Rust, Ruby, Python, Node.js, Deno, .NET SDK 9
- GitHub CLI
- mise (version manager)

#### Neovim Configuration
Run `sudo ./install-neovim.sh` to configure:
- LazyVim / NvChad / AstroNvim / Custom config
- Language servers (bash, TypeScript, YAML, Docker, C#)
- Python tools (black, flake8, pylint, autopep8)

#### Post-Installation
Run `sudo ./post-install.sh` for:
- Shell configuration (Starship, Zoxide)
- Docker group membership
- Service enablement
- GNOME settings
- Hyprland configuration
- Firewall setup

## Key Features

### Dual Desktop Setup
- **GNOME (Wayland)**: Full-featured desktop with all GNOME apps
- **Hyprland**: Tiling Wayland compositor with custom keybindings
- Switch between them at login screen

### Audio Setup
- Pipewire with PulseAudio/ALSA/JACK compatibility
- Wireplumber session manager
- pavucontrol for GUI control
- pamixer for CLI control

### Development Environment
- Multiple language support (Rust, Ruby, Python, Node.js, Deno, .NET)
- GitHub CLI integration
- Docker and Docker Compose
- VS Code with extensions
- Neovim with modern plugins

### Terminal Experience
- Starship prompt
- Zoxide (smart cd)
- Modern replacements: bat (cat), eza (ls), ripgrep (grep), fd (find), dust (du)
- TUI tools: lazygit, lazydocker, btop, atac

### Hyprland Configuration
Custom keybindings and configuration files included:
- `~/.config/hypr/hyprland.conf` - Main configuration
- `~/.config/hypr/bindings.conf` - Custom keybindings
- `~/.config/hypr/monitors.conf` - Multi-monitor setup
- `~/.config/hypr/input.conf` - Keyboard/mouse configuration
- See `debian/hyprland/` directory for all config files

### AUR Packages
The installation uses `yay` for AUR packages:
- brave-bin, visual-studio-code-bin
- discord, spotify, obsidian
- lazygit, lazydocker, starship, zoxide
- nerd fonts and specialized tools

## Post-Installation Steps

### 1. Reboot
```bash
sudo reboot
```

### 2. Run Post-Install Script
```bash
cd ~/setup/linux/arch
sudo ./post-install.sh
```

### 3. Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 4. Set Up SSH Keys
```bash
ssh-keygen -t ed25519 -C "your@email.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### 5. Configure Audio Devices
```bash
wpctl status              # List devices
wpctl set-default [ID]    # Set default
wpctl set-volume [ID] 5%+ # Adjust volume
```

### 6. Choose Desktop Session
At login screen, click gear icon and select:
- **GNOME** - Full desktop environment
- **Hyprland** - Tiling compositor

### 7. Install Development Tools (Optional)
```bash
sudo ./install-dev-tools.sh
```

### 8. Configure Neovim (Optional)
```bash
sudo ./install-neovim.sh
```

## System Services

The installation enables these services:
- `gdm` - Display manager
- `NetworkManager` - Network management
- `bluetooth` - Bluetooth support
- `cups` - Printing
- `docker` - Container runtime
- `ufw` - Firewall
- `sshd` - SSH server

Check status:
```bash
systemctl status gdm NetworkManager bluetooth cups docker ufw sshd
```

## Firewall Configuration

UFW is configured with:
- Default deny incoming
- Default allow outgoing
- SSH allowed (port 22)

Manage firewall:
```bash
sudo ufw status
sudo ufw allow 8080/tcp  # Allow specific port
sudo ufw deny 23/tcp     # Deny specific port
```

## Package Management

### Update System
```bash
sudo pacman -Syu      # Update official repos
yay -Syu              # Update AUR packages
```

### Search Packages
```bash
pacman -Ss package    # Search official repos
yay -Ss package       # Search official + AUR
```

### Install Packages
```bash
sudo pacman -S package    # From official repos
yay -S package            # From AUR
```

### Remove Packages
```bash
sudo pacman -Rns package  # Remove with dependencies
```

### Clean Cache
```bash
sudo pacman -Sc       # Clean pacman cache
yay -Sc               # Clean yay cache
```

## Hyprland Keybindings

Key custom bindings (see `bindings.conf` for all):

| Key | Action |
|-----|--------|
| SUPER + Return | Terminal (gnome-terminal) |
| SUPER + SHIFT + B | Browser (Brave) |
| SUPER + SHIFT + F | File manager (Nautilus) |
| SUPER + SHIFT + N | VS Code |
| SUPER + SHIFT + O | Obsidian |
| SUPER + L | Lock screen |
| SUPER + Q | Close window |
| SUPER + [1-9] | Switch workspace |

Full configuration in `~/.config/hypr/`

## Troubleshooting

### GDM doesn't start
```bash
sudo systemctl enable gdm
sudo systemctl start gdm
```

### Audio not working
```bash
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

### Docker permission denied
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Hyprland won't start
Check logs:
```bash
journalctl -b | grep hyprland
cat ~/.cache/hypr/hyprland.log
```

### NVIDIA issues
Install NVIDIA drivers:
```bash
sudo pacman -S nvidia-open-dkms nvidia-utils libva-nvidia-driver
```

Then reboot.

## Maintenance

### Weekly
```bash
sudo pacman -Syu
yay -Syu
```

### Monthly
```bash
sudo pacman -Sc    # Clean package cache
yay -Sc            # Clean AUR cache
paccache -r        # Keep only 3 most recent versions
```

### Check for orphaned packages
```bash
pacman -Qtdq       # List orphans
sudo pacman -Rns $(pacman -Qtdq)  # Remove orphans
```

## Backup & Restore

### Backup Package List
```bash
pacman -Qe > packages-explicit.txt
pacman -Q > packages-all.txt
```

### Restore from List
```bash
sudo pacman -S --needed - < packages-explicit.txt
```

### Backup Configuration
Important files to backup:
- `~/.config/hypr/` - Hyprland config
- `~/.config/nvim/` - Neovim config
- `~/.bashrc` - Shell config
- `~/.gitconfig` - Git config
- `~/.ssh/` - SSH keys
- `/etc/fstab` - Filesystem mounts
- `/etc/X11/xorg.conf.d/` - X11 config

## Additional Resources

- Arch Wiki: https://wiki.archlinux.org/
- AUR: https://aur.archlinux.org/
- Hyprland: https://wiki.hyprland.org/
- GNOME Extensions: https://extensions.gnome.org/

## Notes

- This setup is based on your current Arch Linux system as of 2026-01-22
- Total of 263 explicitly installed packages
- Includes both official repository and AUR packages
- Optimized for development and daily use
- Uses Wayland by default (both GNOME and Hyprland)
