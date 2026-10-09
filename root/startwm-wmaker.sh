#!/bin/bash
# Start the Window Maker window manager (NeXTSTEP-style desktop)

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=wmaker
export XDG_CURRENT_DESKTOP=WindowMaker

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Window Maker stores its preferences under GNUSTEP_USER_ROOT; make sure the
# directory tree exists so it does not fall back to an unwritable location.
mkdir -p "${HOME:-/config}/GNUstep/Defaults" "${HOME:-/config}/GNUstep/Library"

exec wmaker
