#!/bin/bash
# gsettings values live in dconf, which chezmoi can't manage as files.
# Set the dark-mode preference once so portal-aware apps pick it up.

set -euo pipefail

if ! command -v gsettings >/dev/null 2>&1; then
    echo "gsettings not found, skipping dark theme setup"
    exit 0
fi

gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
