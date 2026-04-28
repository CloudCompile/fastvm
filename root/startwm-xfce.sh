#!/bin/bash
# Start XFCE4 desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE

# Audio + clipboard helpers (no-op if not installed).
if [[ -x /fastvm-scripts/audio-init.sh ]]; then
    /fastvm-scripts/audio-init.sh >/dev/null 2>&1 || true
fi
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec startxfce4
