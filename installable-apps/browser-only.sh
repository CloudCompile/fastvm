#!/bin/bash
# Browser-only variant: Chrome + openbox (no desktop environment)
set -euo pipefail
wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    openbox \
    /tmp/chrome.deb
rm -f /tmp/chrome.deb
rm -rf /var/lib/apt/lists/*

# Desktop shortcut + default prefs
mkdir -p /etc/skel/.config/google-chrome/Default
cat > /etc/skel/.config/google-chrome/Default/Preferences << 'EOF'
{
  "browser": { "check_default_browser": false },
  "homepage": "about:newtab",
  "profile": { "exit_type": "Normal" }
}
EOF
