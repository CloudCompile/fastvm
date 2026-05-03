#!/bin/bash
# Terminal-only variant: xfce4-terminal + openbox (no desktop environment)
set -euo pipefail
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    openbox \
    xfce4-terminal \
    tmux \
    vim \
    htop \
    curl \
    wget \
    git
rm -rf /var/lib/apt/lists/*
