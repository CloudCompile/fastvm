#!/bin/bash
# Start the Fluxbox window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=fluxbox
export XDG_CURRENT_DESKTOP=FLUXBOX

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec startfluxbox
