#!/bin/bash
set -euo pipefail
dpkg --add-architecture i386
install -dm755 /etc/apt/keyrings
wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
wget -qNP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y winehq-stable
rm -rf /var/lib/apt/lists/*
