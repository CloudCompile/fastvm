#!/bin/bash
set -euo pipefail
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y openjdk-17-jre
rm -rf /var/lib/apt/lists/*
