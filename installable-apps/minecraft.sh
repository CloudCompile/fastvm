#!/bin/bash
set -euo pipefail
wget -qO /tmp/minecraft.deb https://launcher.mojang.com/download/Minecraft.deb
DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/minecraft.deb
rm -f /tmp/minecraft.deb
rm -rf /var/lib/apt/lists/*
