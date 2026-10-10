#!/bin/bash
# Start the JWM (Joe's Window Manager) desktop

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=jwm
export XDG_CURRENT_DESKTOP=JWM

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# JWM reads its config from ~/.jwmrc; seed the packaged system config on first run.
mkdir -p "${HOME:-/config}"
if [[ ! -f "${HOME:-/config}/.jwmrc" && -f /etc/jwm/system.jwmrc ]]; then
    cp /etc/jwm/system.jwmrc "${HOME:-/config}/.jwmrc"
fi

exec jwm
