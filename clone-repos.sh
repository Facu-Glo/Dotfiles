#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  Clonando repositorios externos"
echo "========================================"

clone_if_needed() {
    local name="$1"
    local repo="$2"
    local dest="$3"
    if [ ! -d "$dest" ]; then
        echo "  → Clonando $name en $dest"
        mkdir -p "$(dirname "$dest")"
        git clone "$repo" "$dest"
    else
        echo "  ✓ $name ya existe en $dest"
    fi
}

clone_if_needed "nvim"      "https://github.com/Facu-Glo/nvim-configuracion.git" "$HOME/.config/nvim"
clone_if_needed "wallpapers" "https://github.com/Facu-Glo/Wallpapers.git"   "$HOME/Imágenes/Wallpapers"
clone_if_needed "fzf-tab"   "https://github.com/Aloxaf/fzf-tab.git"              "$HOME/.config/fzf-tab"

echo ""
echo "========================================"
echo " Repositorios clonados."
echo "========================================"
