#!/bin/bash

set -e

echo ">>> Updating system and installing base tools..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git base-devel wget curl unzip neofetch zsh \
    ttf-dejavu noto-fonts noto-fonts-emoji noto-fonts-cjk

echo ">>> Installing NVIDIA drivers..."
sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils

echo ">>> Installing audio support (Pipewire + ALSA)..."
sudo pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    wireplumber alsa-utils

echo ">>> Enabling audio service..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo ">>> Installing AUR helper (yay)..."
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo ">>> Installing Hyprland + dependencies..."
sudo pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland \
    waybar rofi wofi alacritty kitty \
    thunar pavucontrol network-manager-applet blueman \
    grim slurp wl-clipboard qt5-wayland qt6-wayland gtk3 \
    brightnessctl playerctl remmina

echo ">>> Installing apps (Discord, Steam, VSCode, Brave)..."
yay -S --noconfirm discord steam visual-studio-code-bin brave-bin \
	mullvad-vpn-bin

echo ">>> Enabling networking..."
sudo systemctl enable --now NetworkManager

echo ">>> Setup complete! Reboot, then log in using Hyprland session."


