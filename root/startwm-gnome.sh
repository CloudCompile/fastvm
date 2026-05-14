#!/bin/bash
# Start GNOME desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=gnome
export XDG_CURRENT_DESKTOP=GNOME

export PULSE_RUNTIME_PATH=/defaults
export PULSE_SERVER=unix:/tmp/pulse-socket
export XDG_RUNTIME_DIR=/defaults
if [[ -x /fastvm-scripts/audio-init.sh ]]; then
    /fastvm-scripts/audio-init.sh >/dev/null 2>&1 || true
fi
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# GNOME on Ubuntu 22.04 needs dbus and dconf properly initialised.
if ! command -v dbus-launch >/dev/null 2>&1; then
    exec gnome-shell --x11
fi

exec dbus-launch --exit-with-session gnome-session
