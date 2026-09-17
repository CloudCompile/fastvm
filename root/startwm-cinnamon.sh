#!/bin/bash
# Start Cinnamon desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=cinnamon
export XDG_CURRENT_DESKTOP=X-Cinnamon

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec cinnamon-session
