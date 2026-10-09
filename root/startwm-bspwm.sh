#!/bin/bash
# Start the bspwm tiling window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=bspwm
export XDG_CURRENT_DESKTOP=bspwm

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# bspwm has no session manager and ships no default config, so seed one from
# the system defaults on first run (the awesome starter uses the same trick).
mkdir -p "${HOME:-/config}/.config/bspwm" "${HOME:-/config}/.config/sxhkd"
if [[ ! -f "${HOME:-/config}/.config/bspwm/bspwmrc" && -f /etc/xdg/bspwm/bspwmrc ]]; then
    cp /etc/xdg/bspwm/bspwmrc "${HOME:-/config}/.config/bspwm/bspwmrc"
fi
if [[ ! -f "${HOME:-/config}/.config/sxhkd/sxhkdrc" && -f /etc/xdg/sxhkd/sxhkdrc ]]; then
    cp /etc/xdg/sxhkd/sxhkdrc "${HOME:-/config}/.config/sxhkd/sxhkdrc"
fi
chmod +x "${HOME:-/config}/.config/bspwm/bspwmrc" 2>/dev/null || true

exec bspwm
