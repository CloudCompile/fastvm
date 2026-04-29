# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is FastVM

FastVM runs a full Linux desktop environment inside a Docker container (built on `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy`), accessible from any browser via KasmVNC. It's designed to run inside a GitHub Codespace — the desktop streams to port 3000 and a management dashboard runs on port 3001/8099.

## Key Commands

```bash
# First-time install (builds image + starts container)
./fastvm-install.sh

# Standard container management
docker-compose up -d
docker-compose stop
docker-compose restart
docker-compose logs -f
docker-compose down

# Rebuild after changes to Dockerfile or scripts
docker-compose build
docker-compose up -d

# Clean rebuild
docker-compose build --no-cache && docker-compose up -d
```

## Configuration

All runtime settings live in `config.env`. Changes require `docker-compose down && ./fastvm-install.sh` to take effect. The file is sourced with `set -a` so all `FASTVM_*` vars are automatically exported to the container.

Key settings:
- `FASTVM_DE` — desktop environment (XFCE4 default; options: KDE, GNOME, Cinnamon, LXQT, I3, Budgie)
- `FASTVM_PRESET` — overlays app/resource defaults (none, minimal, gaming, development, office, content-creation)
- `FASTVM_APP_*` / `FASTVM_PROG_*` — toggle individual app installs
- `FASTVM_DASHBOARD_PORT` — internal port the Node.js dashboard listens on (default 8099 inside container, mapped to host 3001)

## Architecture

### Port mapping
- **3000** → KasmVNC web desktop (served by base image's nginx)
- **3001** (host) → **8099** (container) → Node.js management dashboard

The base image's nginx handles port 3000. The dashboard bypasses it entirely and listens directly on 8099.

### Dockerfile layers (in order)
1. `options.json` + `root/` — KasmVNC config and WM startup scripts
2. System deps (PulseAudio, ffmpeg, xclip, cron, etc.)
3. `fastvm-setup.sh` — installs the chosen desktop environment
4. `installapps-parallel.sh` — installs optional apps from `config.env`
5. `scripts/` → `/opt/fastvm-scripts/` — runtime shell scripts
6. `dashboard/` → `/opt/fastvm-dashboard/` — Node.js dashboard (`npm install` runs here)
7. `presets/` → `/opt/fastvm-presets/` — preset config overlays

### Dashboard (`dashboard/`)
Node.js/Express server (`server.js`) on port 8099. Authentication via a single token stored in `/config/dashboard.token` (auto-generated on first launch). Pass as `?token=...` query param or `Authorization: Bearer ...` header.

API modules in `dashboard/api/`:
- `performance.js` — CPU/memory/disk metrics, WebSocket broadcaster (5s interval)
- `snapshots.js` — backup/snapshot management
- `recording.js` — screen recording control (wraps `scripts/screen-recorder.sh`)
- `clipboard.js` — clipboard sync
- `tasks.js` — scheduled task management

### Shell scripts (`scripts/`)
All scripts source `scripts/lib-common.sh` for logging helpers (`log_info`, `log_success`, `log_warn`, `log_error`, `log_step`) and config loading (`load_fastvm_config`). Use `set -euo pipefail`.

Key scripts:
- `audio-init.sh` — PulseAudio initialization
- `clipboard-daemon.sh` — bidirectional clipboard sync via xclip/xsel
- `screen-recorder.sh` — ffmpeg-based recording
- `backup-create/list/restore/scheduler.sh` — snapshot lifecycle
- `autoscale-monitor.sh` / `autoscale-adjust.sh` — CPU/memory autoscaling

### Persistent storage
`./data/` → `/config` inside container. Always survives `docker-compose down`. Subdirs: `backups/`, `recordings/`, `.fastvm/` (tasks.json, clipboard.txt).

## Shell Script Conventions

- `set -euo pipefail` in all scripts
- Log with `lib-common.sh` helpers, not raw `echo`
- Use `jq -e` instead of `jq | grep`
- Consolidate APT operations into a single `apt-get update`
- No unnecessary `sleep` delays
