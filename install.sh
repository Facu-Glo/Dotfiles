#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Dotfiles - Instalación"
echo "========================================"

# ─────────────────────────────────────────────
# 1. Bootstrap (paquetes + servicios)
# ─────────────────────────────────────────────
"$DOTFILES_DIR/bootstrap.sh"

# ─────────────────────────────────────────────
# 2. Configurar GRUB + tema Vimix
# ─────────────────────────────────────────────
echo "========================================"
echo "  Configurando GRUB..."
echo "========================================"
if [ -d "$DOTFILES_DIR/system/grub/themes/Vimix" ]; then
    sudo mkdir -p /boot/grub/themes
    sudo cp -r "$DOTFILES_DIR/system/grub/themes/Vimix" /boot/grub/themes/
    sudo cp "$DOTFILES_DIR/system/grub/default_grub" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "  ⚠ No se encontró el tema Vimix en system/grub/"
fi

# ─────────────────────────────────────────────
# 3. Instalar findgit
# ─────────────────────────────────────────────
echo "========================================"
echo "  Instalando findgit..."
echo "========================================"
mkdir -p "$HOME/.local/bin"
cp "$DOTFILES_DIR/system/findgit/findgit" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/findgit"

# ─────────────────────────────────────────────
# 4. Stow (symlinks por app)
# ─────────────────────────────────────────────
echo "========================================"
echo "  Vinculando configuraciones con Stow..."
echo "========================================"
cd "$DOTFILES_DIR/stow"
for app in */; do
    app_name="${app%/}"
    echo "  → $app_name"
    stow -R -t "$HOME" "$app_name"
done

# ─────────────────────────────────────────────
# 5. Instalar plugins de Yazi
# ─────────────────────────────────────────────
echo "========================================"
echo "  Instalando plugins de Yazi..."
echo "========================================"
if command -v ya &> /dev/null; then
    ya pkg add yazi-rs/plugins:full-border
    ya pkg add Rolv-Apneseth/starship
else
    echo "  ⚠ ya (yazi) no está instalado. Saltando plugins."
fi

echo ""
echo "========================================"
echo "✅ Instalación completada."
echo "   Recargá tu shell o reiniciá."
echo "========================================"
