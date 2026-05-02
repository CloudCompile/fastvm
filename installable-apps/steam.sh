#!/bin/bash
set -euo pipefail
dpkg --add-architecture i386
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y steam-installer
rm -rf /var/lib/apt/lists/*
