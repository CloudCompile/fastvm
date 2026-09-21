#!/bin/bash
# Install the optional FastVM OS appliance identity layer.
# The desktop shell itself is installed by fastvm-setup.sh; standard images
# remain unchanged.
set -euo pipefail

flavor="${1:-standard}"
if [[ "$flavor" == "standard" ]]; then
    exit 0
fi

if [[ "$flavor" != "fastvm-os" ]]; then
    echo "Unsupported FastVM OS flavor: $flavor" >&2
    exit 1
fi

install -d -m 0755 /etc/fastvm-os /etc/issue.d /usr/local/bin /etc/profile.d /usr/share/applications
cat > /etc/fastvm-os/release <<'EOF'
NAME="FastVM OS"
ID=fastvm-os
PRETTY_NAME="FastVM OS - Browser Desktop Appliance"
VARIANT="browser-desktop"
EOF

cat > /etc/profile.d/fastvm-os.sh <<'EOF'
# FastVM OS identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_OS_NAME="FastVM OS"
EOF

cat > /usr/local/bin/fastvm-os-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/fastvm-os/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-XFCE4}" "${FASTVM_PRESET:-none}"
EOF
chmod 0755 /usr/local/bin/fastvm-os-info

cat > /usr/local/bin/fastvm-os-dashboard <<'EOF'
#!/bin/sh
set -eu
url="${FASTVM_DASHBOARD_URL:-http://127.0.0.1:8099}"
if command -v firefox >/dev/null 2>&1; then
    exec firefox --new-window "$url"
fi
if command -v xdg-open >/dev/null 2>&1; then
    exec xdg-open "$url"
fi
printf 'FastVM dashboard: %s\n' "$url"
EOF
chmod 0755 /usr/local/bin/fastvm-os-dashboard

cat > /usr/local/bin/fastvm-os-theme <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' 'FastVM OS theme: macOS-inspired dark glass'
printf '%s\n' 'Shell: Openbox + Tint2 | Launcher: Rofi | Dock: centered'
EOF
chmod 0755 /usr/local/bin/fastvm-os-theme

cat > /usr/share/applications/fastvm-dashboard.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=FastVM Control Center
Comment=Manage performance, backups, recordings, and tasks
Exec=fastvm-os-dashboard
Icon=applications-system
Terminal=false
Categories=System;Settings;
EOF

printf 'FastVM OS - browser desktop appliance\n' > /etc/issue.d/fastvm-os.issue
echo "Installed FastVM OS identity layer"