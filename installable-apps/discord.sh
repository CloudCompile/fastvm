#!/bin/bash
set -euo pipefail
wget -qO /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/discord.deb
rm -f /tmp/discord.deb
rm -rf /var/lib/apt/lists/*
