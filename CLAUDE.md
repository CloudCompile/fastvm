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
- `FASTVM_DE` — desktop environment (XFCE4 default; options: KDE, GNOME, Cinnamon, LXQT, I3, Budgie, MATE, LXDE, Fluxbox, Unity, UbuntuStudio, Enlightenment, IceWM, awesome, UKUI, fastvm-os)
- `FASTVM_PRESET` — overlays app/resource defaults (none, minimal, gaming, development, office, content-creation, hidencloud-free-vps)
- `FASTVM_APP_BUNDLE` — curated app set baked into the image: precedence `FASTVM_APP_BUNDLE` > preset > desktop default. Options: (empty=auto), none, browser, essentials, communication, gaming, development, office, content-creation. See `docs/app-bundles.md`
- `FASTVM_APP_*` / `FASTVM_PROG_*` — toggle individual app installs (additive on top of the bundle)
- `FASTVM_DASHBOARD_PORT` — internal port the Node.js dashboard listens on (default 8099 inside container, mapped to host 3001)
- `FASTVM_RECORDING_ENCODER` — hardware encoder selection: `auto` (default), `nvenc`, `vaapi`, `qsv`, or `software`
- `FASTVM_ENABLE_GPU_DRIVERS` / `FASTVM_GPU_SELFTEST` — build-time VA-API/Mesa drivers and startup encoder self-test
- `FASTVM_GPU` — compose overlay selection for `./fastvm-install.sh`: `false` (default), `true|intel|amd`, or `nvidia`
- `FASTVM_GPU_HW` — opt in to a GPU-rasterized desktop session (KasmVNC DRI3 + `scripts/gpu-session-env.sh`); disables the compositor on XFCE/KDE/MATE
- `FASTVM_GPU_KEEP_COMPOSITING` — keep desktop compositing even with GPU rasterization (forces CPU/llvmpipe rendering)
- `DISABLE_DRI` — set to `1` to stop KasmVNC from enabling DRI3 (use on compute-only accelerators like AMD Instinct MI300X); FastVM auto-detects these via `compute_only` in `gpu.json`
- `DRINODE` — DRM render node for multi-GPU hosts (default `/dev/dri/renderD128`)
- `FASTVM_PERF_PROFILE` — host performance profile: `auto` (default), `constrained`, `balanced`, `performance`. Auto-measures the container's real CPU/RAM, then clamps llvmpipe (`LP_NUM_THREADS`), frees a core for the recorder (`FASTVM_PERF_ENCODE_THREADS`), and turns off desktop compositing on small hosts. This is what makes a 2-core / 8 GB / no-GPU Codespace usable. See `docs/performance.md`
- `FASTVM_IMAGE` — prebuilt image reference to run instead of building locally (empty = build). `./fastvm-install.sh --pull` derives the published tag from `FASTVM_DE`/`FASTVM_PRESET` and sets this. Used by `.devcontainer/devcontainer.json` so a Codespace starts in ~1 min. See `--print-image` / `--no-build`.
- `FASTVM_CONFIG` — path to an alternate config file (default `./config.env`); lets CI and multi-config setups avoid clobbering the real config

## Architecture

### Port mapping
- **3000** → KasmVNC web desktop (served by base image's nginx)
- **3001** (host) → **8099** (container) → Node.js management dashboard

The base image's nginx handles port 3000. The dashboard bypasses it entirely and listens directly on 8099.

### Dockerfile layers (in order)
1. `root/` — KasmVNC config and WM startup scripts
2. System deps (PulseAudio, ffmpeg, xclip, cron, etc.)
3. `fastvm-setup.sh` — installs the chosen desktop environment
4. `render-options-json.py` generates `options.json` from build args, then `installapps-parallel.sh` installs the bundle + optional apps
5. `scripts/` → `/opt/fastvm-scripts/` — runtime shell scripts
6. `dashboard/` → `/opt/fastvm-dashboard/` — Node.js dashboard (`npm install` runs here)
7. `presets/` → `/opt/fastvm-presets/` — preset config overlays

### Dashboard (`dashboard/`)
Node.js/Express server (`server.js`) on port 8099. Authentication via a single token stored in `/config/dashboard.token` (auto-generated on first launch). Pass as `?token=...` query param or `Authorization: Bearer ...` header.

API modules in `dashboard/api/`:
- `performance.js` — CPU/memory/disk metrics, WebSocket broadcaster (5s interval)
- `gpu.js` — GPU capabilities (from `gpu.json`) and live NVIDIA metrics
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
