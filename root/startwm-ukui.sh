#!/bin/bash
# Start the UKUI desktop environment (Ubuntu Kylin's desktop)

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=ukui
export XDG_CURRENT_DESKTOP=UKUI

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# UKUI is GTK/Qt based and reads dconf/gsettings via the session bus.
if command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session ukui-session
fi

exec ukui-session
