#!/bin/bash
# Start Budgie desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=budgie-desktop
export XDG_CURRENT_DESKTOP=Budgie:GNOME

# Make sure dconf has somewhere to live (Budgie is GNOME-based).
mkdir -p "${HOME:-/config}/.config/dconf"

# Audio + clipboard helpers ride along with the session if they're present.
if [[ -x /fastvm-scripts/audio-init.sh ]]; then
    /fastvm-scripts/audio-init.sh >/dev/null 2>&1 || true
fi
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec budgie-desktop
