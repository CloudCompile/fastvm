#!/bin/bash
set -euo pipefail
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y synaptic
rm -rf /var/lib/apt/lists/*
