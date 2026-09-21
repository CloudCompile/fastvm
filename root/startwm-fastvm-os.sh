#!/bin/bash
# FastVM OS desktop shell: Openbox + Tint2 + Rofi, not XFCE.
set -u

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=fastvm-os
export XDG_CURRENT_DESKTOP=FastVM:Openbox

xsetroot -solid '#0b1220' 2>/dev/null || true

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

openbox --config-file /etc/xdg/openbox/fastvm-os-rc.xml >/dev/null 2>&1 &
tint2 -c /etc/xdg/tint2/fastvm-os.tint2rc >/dev/null 2>&1 &

# Keep a useful first window visible while retaining a clean custom shell.
sleep 1
xterm -title 'FastVM OS Welcome' -geometry 100x28+80+100 \
    -fa 'DejaVu Sans Mono' -fs 12 \
    -e sh -c 'printf "\\033[1;36m  FASTVM OS\\033[0m\\n\\033[2m  browser desktop appliance\\033[0m\\n\\n  Desktop ready.\\n\\n  Super+Space  App launcher\\n  Super+T      Terminal\\n\\n"; exec bash' \
    >/dev/null 2>&1 &

wait