<div align="center">

# ⚡ FastVM ⚡
### Linux Desktop. Streamed. Instant.

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Jetbrains+Mono&size=18&duration=3000&pause=1000&color=00D4FF&center=true&vCenter=true&width=500&lines=Full+Linux+desktop+in+your+browser;Deploy+in+30+seconds;14+variants+ready+to+go;Zero+setup+required;Just+fork+and+code)](https://git.io/typing-svg)

<br/>

</div>

---

## 🎯 One-Liner

```bash
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest
# Open http://localhost:3000 → Full Linux desktop. Done. 🚀
```

---

## ✨ What is FastVM?

**Transform your browser into a full-featured Linux desktop environment.**

- 🚀 **Deploy in 30 seconds** — 14 prebuilt images, production-ready
- 🎨 **7 desktop choices** — XFCE4, KDE, GNOME, Cinnamon, LXQT, i3, Budgie
- ☁️ **Cloud-native** — GitHub Codespaces, Docker, scale anywhere
- 💻 **Zero setup** — No local installation, no configuration hell
- 🎮 **Gaming-ready** — Wine, Steam, GPU passthrough support
- 📊 **Full dashboard** — Monitor CPU/RAM, manage backups, control recording
- 🔊 **Audio + clipboard** — PulseAudio forwarding, bidirectional sync
- 💾 **Persistent data** — Snapshots, automatic backups, point-in-time restore

---

## 📦 Pick Your Flavor

| | **Fast** ⚡ | **Standard** 🔧 | **Best For** |
|:---:|---|---|---|
| 🏃 **XFCE4** | `xfce4-fast` | `xfce4` | ⭐ **Default** — balanced speed |
| 👑 **KDE** | `kde-fast` | `kde` | Power users, customization |
| 🍒 **GNOME** | `gnome-fast` | `gnome` | Modern, sleek interface |
| 🎨 **Cinnamon** | `cinnamon-fast` | `cinnamon` | Windows users, familiar |
| 🪶 **LXQT** | `lxqt-fast` | `lxqt` | Ultralight, 2-core friendly |
| ⌨️ **i3** | `i3-fast` | `i3` | Tiling, keyboard-driven |
| 🎯 **Budgie** | `budgie-fast` | `budgie` | Clean, minimal design |

**Full name format:** `ghcr.io/cloudcompile/fastvm:{variant}-latest`

---

## 🚀 Quick Start

### Option 1: Docker (30 seconds)
```bash
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest
```

### Option 2: GitHub Codespaces (1-2 minutes)
1. **Fork** this repo
2. **Code → Codespaces → Create codespace on main**
3. **Edit `config.env`** (optional)
4. **`./fastvm-install.sh`**
5. **Ports tab → Click 🌐 on port 3000**

Then open `http://localhost:3000` in your browser. 🎉

---

## 🎯 Features at a Glance

### ⚡ Performance
- **30-second startup** with fast variants
- **14 parallel Docker builds** via GitHub Actions
- **Layer caching** for instant rebuilds
- **Optimized images** — fast: 1.2GB, standard: 2.5GB

### 🎨 Customization
- **5 presets** — gaming, development, office, media, minimal
- **Per-app toggles** — `FASTVM_APP_*` variables
- **Desktop choice** — switch via `FASTVM_DE`
- **One `config.env` file** controls everything

### 📊 Management
- **Live dashboard** on port 3001
- **CPU/RAM monitoring** with graphs
- **Screen recording** (ffmpeg)
- **Snapshots & backups** with restore
- **Clipboard sync** (bidirectional)

### 🎮 Gaming
- **Wine support** (x86-64 + i386)
- **Steam integration**
- **Proton compatibility**
- **GPU access** via /dev/dri

### 🔧 Developer Tools
- **VSCodium** pre-installed option
- **Node.js, Git, Docker** in dev preset
- **Terminal + browser** for quick work
- **SSH possible** via port mapping

---

## 📋 Configuration

Edit `config.env`:

```bash
# Desktop environment
FASTVM_DE=XFCE4              # XFCE4 | KDE | GNOME | Cinnamon | LXQT | i3 | Budgie

# App bundle preset
FASTVM_PRESET=minimal         # none | minimal | gaming | development | office | content-creation

# Individual app toggles
FASTVM_APP_CHROME=true       # Install Chrome
FASTVM_APP_WINE=false        # Windows app support
FASTVM_PROG_AUDIO=true       # PulseAudio system
FASTVM_PROG_RECORDING=true   # Screen recording

# System settings
FASTVM_TZ=America/New_York   # Your timezone
FASTVM_SHM_SIZE=2gb          # Shared memory for audio
```

---

## 🐳 Container Management

```bash
# Start/stop
docker-compose up -d         # Start
docker-compose stop          # Stop (data safe)
docker-compose restart       # Restart

# Logs
docker-compose logs -f       # Watch logs

# Rebuild
docker-compose build
docker-compose up -d

# Dashboard
# http://localhost:3001
# Token: cat data/dashboard.token
```

---

## ⚡ Performance Breakdown

| Variant | Size | Startup | Best For |
|:---|:---:|:---:|:---|
| **xfce4-fast** | 1.5 GB | 30s | ⭐ Recommended |
| **lxqt-fast** | 1.2 GB | 25s | 2-core machines |
| **i3-fast** | 1.1 GB | 20s | Keyboard power users |
| **xfce4** | 2.1 GB | 45s | Full featured |
| **kde** | 2.8 GB | 75s | Maximum features |

---

## 🖥️ Machine Size Guide

| Codespace | Desktop | Works? | Experience |
|:---:|:---|:---:|:---|
| 2-core / 8GB | XFCE4, LXQT | ✅ | Functional |
| 4-core / 16GB | XFCE4, KDE, Cinnamon | ✅✅ | **Recommended** |
| 8-core / 32GB | Any | ✅✅✅ | Butter smooth |

---

## 🛠️ Troubleshooting

**Port not loading?**
```bash
# Wait 60s, then check:
docker ps                    # Is it running?
docker-compose logs          # What went wrong?
```

**Desktop slow?**
```bash
# In config.env:
FASTVM_DE=XFCE4             # Switch to light desktop
FASTVM_PRESET=minimal        # Strip down to essentials
FASTVM_SHM_SIZE=4gb         # Add more RAM
```

**Config changes not working?**
```bash
# Config only applies on fresh start:
docker-compose down
./fastvm-install.sh
```

---

## 📁 Project Structure

```
fastvm/
├── config.env              ← Your settings
├── Dockerfile.optimized    ← Multi-stage build
├── docker-compose.yml      ← Container setup
├── fastvm-install.sh       ← One-cmd installer
├── fastvm-setup.sh         ← Desktop setup
├── installapps-parallel.sh ← App installer
├── dashboard/              ← Web UI (port 3001)
├── scripts/                ← Runtime helpers
├── installable-apps/       ← App scripts (14 total)
├── presets/                ← App bundles
├── data/                   ← Persistent storage
└── .github/workflows/      ← CI/CD (14 parallel builds)
```

---

## 🎮 Presets Explained

### `minimal` — Speed focused
- Terminal + browser only
- ~1.7 GB image
- 30-second startup
- Perfect for quick tasks

### `gaming` — Steam ready
- Wine + Proton + Steam
- 32-bit game support
- GPU access
- Full performance

### `development` — Coder's dream
- VSCodium + Git
- Node.js + Docker
- All dev tools
- Ready to code

### `office` — Productivity
- LibreOffice suite
- Browser + Calc + Writer
- PDF support
- Familiar interface

### `content-creation` — Media studio
- GIMP + Blender
- VLC + Audacity
- ffmpeg ready
- High CPU usage

---

## 📊 Dashboard Features

### Monitor
- Live CPU, RAM, disk graphs
- Real-time WebSocket updates
- System health checks
- Performance metrics

### Manage
- Create/restore snapshots
- Screen recording control
- Scheduled backups
- Clipboard sync toggle

### Configure
- Restart services
- Adjust resources
- View system info
- Access logs

**Access:** `http://localhost:3001?token=<your-token>`

---

## 🎛️ Desktop Environments

| Desktop | RAM | Speed | Style | Best For |
|:---|:---:|:---:|:---|:---|
| **XFCE4** ⭐ | 512MB | ⚡⚡⚡ | Classic GTK | Default choice |
| **KDE** | 1.5GB | ⚡⚡ | Modern, Qt | Feature rich |
| **GNOME** | 2GB | ⚡ | Sleek | Modern look |
| **Cinnamon** | 1GB | ⚡⚡⚡ | Windows-like | Comfortable |
| **LXQT** | 256MB | ⚡⚡⚡⚡ | Ultralight | Minimal |
| **i3** | 128MB | ⚡⚡⚡⚡⚡ | Tiling | Keyboard-driven |
| **Budgie** | 512MB | ⚡⚡⚡⚡ | Minimal | Clean |

---

## 🌐 Deployment Options

### Local Docker
```bash
docker-compose up -d
# Open http://localhost:3000
```

### GitHub Codespaces
```bash
# Fork → Codespaces → ./fastvm-install.sh
# Best for: Zero setup, cloud-native
```

### Kubernetes / Cloud
```bash
# Modify docker-compose.yml for your platform
# Works on: AWS, GCP, Azure, Digital Ocean
```

### Multiple Machines
```bash
# Scale horizontally with image variants
# Each variant optimized for specific use case
```

---

## 🤝 Contributing

We welcome contributions! Code standards:

- `set -euo pipefail` in all scripts
- Log with `log_info`, `log_success`, `log_warn`, `log_error`
- `jq -e` over `jq | grep`
- One `apt-get update` per Dockerfile layer
- No unnecessary `sleep` statements

**Submit a PR:**
1. Fork → branch → code
2. Test on multiple desktops
3. Keep PRs focused (one feature)
4. Clear commit messages

---

## 📜 License & Attribution

**MIT License** — Free for personal & commercial use.

Built with ❤️ by **CloudCompile**

**Powered by:**
- [LinuxServer.io](https://linuxserver.io) — Base image
- [KasmVNC](https://kasmweb.com) — Browser streaming
- [Ubuntu 22.04](https://ubuntu.com) — Base OS
- [Docker](https://docker.com) — Containerization
- [Node.js](https://nodejs.org) — Dashboard backend
- [GitHub Actions](https://github.com/features/actions) — CI/CD

---

<div align="center">

### 💝 Love FastVM?

**[⭐ Star this repo](https://github.com/CloudCompile/fastvm/stargazers)** • **[🐛 Report Bug](https://github.com/CloudCompile/fastvm/issues/new)** • **[💡 Request Feature](https://github.com/CloudCompile/fastvm/issues/new)** • **[💬 Discuss](https://github.com/CloudCompile/fastvm/discussions)**

<br/>

> **"Linux. In a tab. On demand. Fast."** ⚡

</div>
