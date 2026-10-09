#!/bin/bash
# Start the GNOME Flashback desktop session (classic GNOME 2 panel layout)

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=gnome-flashback
export XDG_CURRENT_DESKTOP=GNOME-Flashback:GNOME

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Flashback reads dconf/gsettings through the session bus.
if command -v dbus-launch >/dev/null 2>&1; then
    exec dbus-launch --exit-with-session gnome-session --session=gnome-flashback-metacity
fi

exec gnome-session --session=gnome-flashback-metacity
