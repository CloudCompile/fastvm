#!/bin/bash
# Minimal openbox window manager - auto-launches a single app fullscreen
# Used by single-app variants: browser, discord, vscode, terminal, etc.
set -euo pipefail

export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR=/defaults
export PULSE_RUNTIME_PATH=/defaults
export PULSE_SERVER=unix:/tmp/pulse-socket

# Start audio if available
if [[ -x /fastvm-scripts/audio-init.sh ]]; then
    /fastvm-scripts/audio-init.sh >/dev/null 2>&1 || true
fi

# Clipboard sync
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Write openbox autostart to launch the target app fullscreen
AUTOSTART_DIR="/config/.config/openbox"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/autostart" << AUTOSTART
# FastVM single-app autostart
sleep 1
AUTOSTART

# Append the app launch command if set
if [[ -n "${FASTVM_SINGLEAPP_CMD:-}" ]]; then
    echo "${FASTVM_SINGLEAPP_CMD} &" >> "$AUTOSTART_DIR/autostart"
fi

# Openbox config: no decorations, maximize everything
cat > "$AUTOSTART_DIR/rc.xml" << 'RC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <applications>
    <application class="*">
      <maximized>yes</maximized>
      <decorations>no</decorations>
    </application>
  </applications>
  <theme>
    <font place="ActiveWindow"><size>1</size></font>
  </theme>
  <desktops><number>1</number></desktops>
  <keyboard>
    <keybind key="A-F4"><action name="Close"/></keybind>
  </keyboard>
</openbox_config>
RC

exec openbox-session
