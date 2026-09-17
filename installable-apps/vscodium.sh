#!/bin/bash
set -euo pipefail
install -d -m 0755 /etc/apt/keyrings
wget -qO /etc/apt/keyrings/vscodium-archive-keyring.gpg \
    https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
echo "deb [ signed-by=/etc/apt/keyrings/vscodium-archive-keyring.gpg ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main" \
    > /etc/apt/sources.list.d/vscodium.list
chmod 0644 /etc/apt/keyrings/vscodium-archive-keyring.gpg
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y codium
rm -rf /var/lib/apt/lists/*
