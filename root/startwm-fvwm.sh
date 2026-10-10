#!/bin/bash
# Start the FVWM (F? Virtual Window Manager) desktop

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=fvwm
export XDG_CURRENT_DESKTOP=FVWM

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# FVWM reads ~/.fvwm/config on startup; seed the packaged default when the user
# has not customised it yet so a fresh session opens with menus and a pager.
USERDIR="${HOME:-/config}/.fvwm"
FVWM_DATADIR="$(fvwm-config -d 2>/dev/null || echo /usr/share/fvwm)"
mkdir -p "$USERDIR"
if [[ ! -f "$USERDIR/config" && -f "$FVWM_DATADIR/default-config/config" ]]; then
    cp "$FVWM_DATADIR/default-config/config" "$USERDIR/config"
fi

exec fvwm2
