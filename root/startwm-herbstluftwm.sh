#!/bin/bash
# Start the herbstluftwm tiling window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=herbstluftwm
export XDG_CURRENT_DESKTOP=herbstluftwm

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# herbstluftwm reads $XDG_CONFIG_HOME/herbstluftwm/autostart; seed the packaged
# default when the user has not customised it yet.
mkdir -p "${HOME:-/config}/.config/herbstluftwm"
if [[ ! -f "${HOME:-/config}/.config/herbstluftwm/autostart" && -f /etc/xdg/herbstluftwm/autostart ]]; then
    cp /etc/xdg/herbstluftwm/autostart "${HOME:-/config}/.config/herbstluftwm/autostart"
fi

exec herbstluftwm
