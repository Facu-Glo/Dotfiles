#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Configurando pacman..."
echo "========================================"
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
grep -q "^ILoveCandy" /etc/pacman.conf || sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf

echo "========================================"
echo "  Actualizando el sistema..."
echo "========================================"
sudo pacman -Syu --noconfirm

echo "========================================"
echo "  Instalando paquetes pacman..."
echo "========================================"
sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/pacman-utils.txt"

echo "========================================"
echo "  Instalando yay..."
echo "========================================"
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd - && rm -rf /tmp/yay
fi

echo "========================================"
echo "  Instalando paquetes AUR..."
echo "========================================"
yay -S --needed --noconfirm - < "$DOTFILES_DIR/packages/aur.txt"

echo "========================================"
echo "  Creando directorios XDG..."
echo "========================================"
xdg-user-dirs-update --force

echo "========================================"
echo "  Instalando paquetes de escritorio..."
echo "========================================"
sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/pacman-desktop.txt"

echo "========================================"
echo "  Habilitando servicios..."
echo "========================================"
sudo systemctl enable bluetooth.service
sudo systemctl enable sddm.service
sudo systemctl enable tlp.service

echo "✅ Bootstrap completado."
