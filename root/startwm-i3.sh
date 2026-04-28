#!/bin/bash
# Start i3 window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=i3
export XDG_CURRENT_DESKTOP=i3

if [[ -x /fastvm-scripts/audio-init.sh ]]; then
    /fastvm-scripts/audio-init.sh >/dev/null 2>&1 || true
fi
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec i3
