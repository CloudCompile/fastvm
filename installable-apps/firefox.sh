#!/bin/bash
# Firefox installation script
set -euo pipefail
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    firefox
rm -rf /var/lib/apt/lists/*
