#!/bin/bash
# Start the awesome tiling window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=awesome
export XDG_CURRENT_DESKTOP=awesome

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# awesome looks for rc.lua under XDG_CONFIG_HOME; fall back to the system copy
# when the user has not customised it yet.
mkdir -p "${HOME:-/config}/.config/awesome"
if [[ ! -f "${HOME:-/config}/.config/awesome/rc.lua" && -f /etc/xdg/awesome/rc.lua ]]; then
    cp /etc/xdg/awesome/rc.lua "${HOME:-/config}/.config/awesome/rc.lua"
fi

exec awesome
