#!/bin/bash
# Start the Unity desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=unity
export XDG_CURRENT_DESKTOP=Unity

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Unity builds on GNOME session infrastructure, so dbus must be running.
if command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session unity
fi

exec unity
