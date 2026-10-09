#!/bin/bash
# Start the Enlightenment desktop environment

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=enlightenment
export XDG_CURRENT_DESKTOP=Enlightenment

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Enlightenment needs a writable config/cache home on first run.
mkdir -p "${HOME:-/config}/.e" "${HOME:-/config}/.cache"

exec dbus-launch --exit-with-session enlightenment_start
