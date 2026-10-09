#!/bin/bash
# Start the IceWM window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=icewm
export XDG_CURRENT_DESKTOP=IceWM

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec icewm-session
