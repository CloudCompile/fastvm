#!/bin/bash
# Discord-only variant: Discord + openbox (no desktop environment)
set -euo pipefail
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    openbox \
    libatomic1 \
    libgbm1 \
    libasound2
wget -qO /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y /tmp/discord.deb
rm -f /tmp/discord.deb
rm -rf /var/lib/apt/lists/*
