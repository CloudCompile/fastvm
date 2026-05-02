#!/bin/bash
set -euo pipefail
wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/chrome.deb
rm -f /tmp/chrome.deb
rm -rf /var/lib/apt/lists/*
