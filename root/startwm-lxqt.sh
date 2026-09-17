#!/bin/bash
# Start LXQt desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=LXQt
export XDG_CURRENT_DESKTOP=LXQt

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

exec startlxqt
