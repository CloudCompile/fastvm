#!/bin/bash
# Start Budgie desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=budgie-desktop
export XDG_CURRENT_DESKTOP=Budgie:GNOME

# Make sure dconf has somewhere to live (Budgie is GNOME-based).
mkdir -p "${HOME:-/config}/.config/dconf"

# Clipboard helper rides along with the session if present; KasmVNC owns audio.
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec budgie-desktop
