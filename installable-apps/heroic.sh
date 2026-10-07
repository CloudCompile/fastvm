#!/bin/bash
set -euo pipefail

if ! command -v flatpak >/dev/null 2>&1; then
    /installable-apps/flatpak.sh
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --noninteractive -y flathub com.heroicgameslauncher.hgl
