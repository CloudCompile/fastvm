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

install -d -m 0755 /etc/fastvm-os /etc/issue.d /usr/local/bin /etc/profile.d
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

printf 'FastVM OS - browser desktop appliance\n' > /etc/issue.d/fastvm-os.issue
echo "Installed FastVM OS identity layer"