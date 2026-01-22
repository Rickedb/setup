# Debian Configuration

This configuration mirrors your Arch Linux setup as closely as possible for Debian-based systems.

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

### Installed Applications & Tools

| Category | Tool/App | Purpose |
|----------|----------|---------|
| **Base Development** | build-essential | GCC, G++, Make and essential build tools |
| | cmake | Cross-platform build system |
| | clang | C/C++/Objective-C compiler |
| | llvm | Compiler infrastructure |
| | git | Version control system |
| | neovim | Modern text editor |
| | vim | Classic text editor |
| | tmux | Terminal multiplexer |
| **CLI Utilities** | bat (batcat) | Cat clone with syntax highlighting |
| | fd (fd-find) | Fast alternative to find |
| | ripgrep | Fast text search tool |
| | fzf | Fuzzy finder |
| | eza | Modern ls replacement |
| | dust | Disk usage analyzer (du replacement) |
| | btop | Resource monitor |
| | htop | Interactive process viewer |
| | tldr | Simplified man pages |
| | jq | JSON processor |
| | yq | YAML processor |
| | tree | Directory tree viewer |
| | plocate | Fast file locator |
| | inxi | System information tool |
| | fastfetch | System info display |
| | whois | Domain information lookup |
| **Filesystem** | btrfs-progs | BTRFS filesystem utilities |
| | dosfstools | FAT filesystem utilities |
| | exfatprogs | exFAT filesystem support |
| | ntfs-3g | NTFS filesystem support |
| | snapper | BTRFS snapshot manager |
| **Desktop Environment** | gnome-shell | GNOME desktop shell |
| | gnome-session | GNOME session manager |
| | gdm3 | GNOME Display Manager |
| | gnome-control-center | GNOME settings |
| | gnome-tweaks | Advanced GNOME settings |
| | nautilus | GNOME file manager |
| | gnome-terminal | GNOME terminal emulator |
| | gnome-console | Modern GNOME terminal |
| | gnome-calculator | Calculator app |
| | gnome-calendar | Calendar application |
| | gnome-maps | Maps application |
| | gnome-music | Music player |
| | gnome-weather | Weather application |
| | gnome-clocks | World clock and timers |
| | evince | PDF viewer |
| | eog | Image viewer |
| | file-roller | Archive manager |
| | baobab | Disk usage analyzer |
| | simple-scan | Document scanner |
| | cheese | Webcam application |
| | totem | Video player |
| **Wayland Compositor** | hyprland | Dynamic tiling Wayland compositor |
| | hyprlock | Screen locker for Hyprland |
| | hypridle | Idle management daemon |
| | hyprpicker | Color picker |
| | hyprpaper | Wallpaper utility |
| | xdg-desktop-portal-hyprland | Screen sharing support |
| **Wayland Tools** | wlroots | Wayland compositor library |
| | grim | Screenshot utility |
| | slurp | Region selector |
| | wl-clipboard | Clipboard utilities |
| | swaybg | Wallpaper setter |
| | mako-notifier | Notification daemon |
| | swayidle | Idle management |
| **Audio/Video** | pipewire | Modern audio/video server |
| | pipewire-pulse | PulseAudio replacement |
| | wireplumber | Session/policy manager |
| | pavucontrol | Volume control GUI |
| | pamixer | CLI volume control |
| | playerctl | Media player controller |
| | mpv | Minimal video player |
| | vlc | Feature-rich media player |
| | obs-studio | Live streaming/recording |
| | ffmpegthumbnailer | Video thumbnail generator |
| **Graphics** | gimp | Image editor |
| | imagemagick | Image manipulation CLI |
| | kdenlive | Video editor |
| **Networking** | network-manager | Network connection manager |
| | network-manager-gnome | NM GUI applet |
| | iwd | Wireless daemon |
| | avahi-daemon | Service discovery |
| | ufw | Uncomplicated Firewall |
| | openssh-client | SSH client |
| | openssh-server | SSH server |
| **Bluetooth** | bluez | Bluetooth stack |
| | blueman | Bluetooth manager GUI |
| **Printing** | cups | Printing system |
| | cups-pdf | PDF printer |
| | system-config-printer | Printer configuration GUI |
| **Fonts** | fonts-noto | Google Noto fonts |
| | fonts-noto-cjk | CJK (Chinese/Japanese/Korean) fonts |
| | fonts-noto-color-emoji | Emoji fonts |
| | fonts-liberation | Liberation fonts |
| | fonts-font-awesome | Icon fonts |
| **Browsers** | brave-browser | Privacy-focused browser |
| **Office** | libreoffice | Office suite |
| **Remote Desktop** | remmina | Remote desktop client |
| | freerdp2-x11 | RDP protocol support |
| **Containerization** | docker.io | Container platform |
| | docker-compose | Multi-container orchestration |
| **Virtualization** | qemu-kvm | Hardware virtualization |
| | libvirt-daemon-system | Virtualization API |
| | virt-manager | Virtual machine manager |
| | gnome-boxes | Simple VM manager |
| **Power Management** | power-profiles-daemon | Power profile management |
| | tlp | Advanced power management |
| | brightnessctl | Screen brightness control |
| **Firmware** | firmware-linux | Linux firmware |
| | firmware-linux-nonfree | Non-free firmware |
| | intel-microcode | Intel CPU microcode |
| **Flatpak Apps** | md.obsidian.Obsidian | Knowledge base/note taking |
| **System Libraries** | libpq-dev | PostgreSQL development files |
| | libmariadb-dev | MariaDB development files |
| | libyaml-dev | YAML library |
| | libqalculate-dev | Calculator library |
| | gvfs | GNOME virtual filesystem |

### Optional Development Tools

Run `sudo ./install-dev-tools.sh` separately to install:

| Tool/Language | Purpose |
|--------------|---------|
| Rust | Systems programming language |
| Ruby | Dynamic programming language |
| Python 3 | High-level programming language |
| Node.js | JavaScript runtime |
| .NET SDK 9 | Microsoft development platform |
| GitHub CLI (gh) | GitHub command-line tool |
| Starship | Cross-shell prompt |
| Lazygit | Terminal UI for Git |
| Lazydocker | Terminal UI for Docker |
| Zoxide | Smarter cd command |
| VS Code | Code editor/IDE |

## Manual Installation Required

Some packages from your Arch system are not available in Debian repositories or require manual installation:

### Hyprland
Hyprland is not packaged for Debian. To install:
1. Follow the official guide: https://wiki.hyprland.org/Getting-Started/Installation/
2. Or use a compatible compositor like Sway (available in Debian repos)

Install Sway as an alternative:
```bash
sudo apt install sway waybar swaylock swayidle
```

### Hyprland-related packages
If you build Hyprland from source, you'll also need to manually install:
- hyprlock
- hypridle
- hyprpicker
- hyprsunset
- waybar (available in Debian)

### NVIDIA Drivers
If you need NVIDIA drivers (you have nvidia-open-dkms on Arch):

For proprietary drivers:
```bash
sudo apt install nvidia-driver firmware-misc-nonfree
```

For open-source nouveau:
```bash
sudo apt install xserver-xorg-video-nouveau
```

### Ghostty Terminal
Ghostty is not packaged for Debian. Build from source:
```bash
git clone https://github.com/ghostty-org/ghostty
cd ghostty
# Follow build instructions in repo
```

### AUR-specific packages
These packages are only available in the AUR and have no direct Debian equivalent:
- aether
- asdcontrol
- atac
- bluetui
- chatty
- dbeaver (use Flatpak version)
- decibels
- endeavour
- gpu-screen-recorder
- usage
- wiremix
- Many omarchy-* packages

### Alternative Solutions

For some Arch-specific tools, consider these Debian alternatives:

| Arch Package | Debian Alternative |
|-------------|-------------------|
| yay | apt + flatpak |
| pamac | gnome-software |
| ghostty | gnome-console, kitty, alacritty |
| gpu-screen-recorder | obs-studio, simplescreenrecorder |

## Post-Installation

1. **Reboot your system** to ensure all services start properly

2. **Configure Flatpak applications**:
```bash
flatpak update
```

3. **Set up shell prompt** (Starship):
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
eval "$(starship init bash)"  # or zsh
```

4. **Configure Zoxide**:
Add to your shell config:
```bash
eval "$(zoxide init bash)"  # or zsh
```

5. **Set up Docker** (non-root access):
```bash
sudo usermod -aG docker $USER
```
Then log out and back in.

6. **Configure UFW firewall**:
```bash
sudo ufw status
sudo ufw allow ssh  # if needed
```

7. **Enable services**:
```bash
sudo systemctl enable bluetooth
sudo systemctl enable cups
sudo systemctl enable avahi-daemon
```

## Package Mapping Reference

Here's how major Arch packages map to Debian:

| Arch | Debian |
|------|--------|
| base, base-devel | build-essential |
| pacman | apt |
| yay | flatpak for third-party apps |
| bat | batcat (symlinked to bat) |
| fd | fd-find (symlinked to fd) |
| docker | docker.io |
| python | python3 |
| dotnet-sdk | dotnet-sdk-9.0 |

## Differences from Arch

1. **Package names**: Some packages have different names in Debian
2. **Release cycle**: Debian Stable has older packages than Arch
3. **Repositories**: No AUR equivalent - use Flatpak, Snap, or build from source
4. **Init system**: Both use systemd, but some service names differ
5. **Policies**: Debian separates free and non-free software more strictly

## Troubleshooting

### If GDM doesn't start
```bash
sudo systemctl enable gdm
sudo systemctl start gdm
```

### If audio doesn't work
```bash
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

### If Flatpak apps don't appear
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update
```

### Graphics issues
```bash
# Check current driver
lspci -k | grep -A 3 -E "(VGA|3D)"

# For Intel
sudo apt install intel-media-va-driver

# For AMD
sudo apt install mesa-vulkan-drivers libva-mesa-driver
```

## Maintenance

Update system regularly:
```bash
sudo apt update && sudo apt upgrade -y
flatpak update -y
```

Clean old packages:
```bash
sudo apt autoremove
sudo apt autoclean
```

## Additional Resources

- Debian Wiki: https://wiki.debian.org/
- Debian Package Search: https://packages.debian.org/
- Flatpak: https://flatpak.org/
- GNOME Extensions: https://extensions.gnome.org/
