#!/bin/bash
# Start MATE desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=mate
export XDG_CURRENT_DESKTOP=MATE

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# MATE is GTK2/GTK3 based and reads dconf/gsettings.
if command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session mate-session
fi

exec mate-session
