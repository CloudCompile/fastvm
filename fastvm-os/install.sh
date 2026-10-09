#!/bin/bash
# Install the optional FastVM OS appliance identity layer.
# The desktop shell itself is installed by fastvm-setup.sh; standard images
# remain unchanged.
set -euo pipefail

flavor="${1:-standard}"
if [[ "$flavor" == "standard" ]]; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Studio.
# Ubuntu Studio is an official Ubuntu 22.04 flavor (KDE Plasma based). The
# desktop packages are installed by fastvm-setup.sh; this layer only writes
# distro identity files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-studio" ]]; then
    install -d -m 0755 /etc/ubuntu-studio /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-studio/release <<'EOF'
NAME="Ubuntu Studio"
ID=ubuntu-studio
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Studio 22.04 LTS (FastVM flavor)"
VARIANT="KDE Plasma multimedia workstation"
EOF

    cat > /etc/profile.d/ubuntu-studio.sh <<'EOF'
# Ubuntu Studio identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-studio"
EOF

    cat > /usr/local/bin/ubuntu-studio-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-studio/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-UBUNTUSTUDIO}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-studio-info

    printf 'Ubuntu Studio 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-studio.issue
    echo "Installed Ubuntu Studio distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Kylin.
# Ubuntu Kylin is an official Ubuntu 22.04 flavor whose UKUI desktop is
# packaged in the Ubuntu archive. The desktop packages are installed by
# fastvm-setup.sh (FASTVM_DE=UKUI); this layer only writes distro identity
# files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-kylin" ]]; then
    install -d -m 0755 /etc/ubuntu-kylin /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-kylin/release <<'EOF'
NAME="Ubuntu Kylin"
ID=ubuntu-kylin
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Kylin 22.04 LTS (FastVM flavor)"
VARIANT="UKUI desktop, Chinese-localised Ubuntu flavor"
EOF

    cat > /etc/profile.d/ubuntu-kylin.sh <<'EOF'
# Ubuntu Kylin identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-kylin"
EOF

    cat > /usr/local/bin/ubuntu-kylin-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-kylin/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-UKUI}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-kylin-info

    printf 'Ubuntu Kylin 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-kylin.issue
    echo "Installed Ubuntu Kylin distro identity layer"
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