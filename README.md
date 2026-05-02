<div align="center">

<!-- HERO BANNER -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=200&section=header&text=FastVM&fontSize=80&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=Linux%20Desktop.%20In%20a%20Tab.&descAlignY=55&descSize=24&descColor=c4b5fd"/>
  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=200&section=header&text=FastVM&fontSize=80&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=Linux%20Desktop.%20In%20a%20Tab.&descAlignY=55&descSize=24&descColor=c4b5fd"/>
</picture>

<!-- TYPING ANIMATION -->
[![Typing SVG](https://readme-typing-svg.demolab.com?font=JetBrains+Mono&size=18&pause=1000&color=6366F1&center=true&vCenter=true&width=600&lines=Full+Linux+desktop+in+your+browser+%E2%9A%A1;Deploy+in+30+seconds+with+prebuilt+images+%F0%9F%9A%80;7+desktop+environments+to+choose+from+%F0%9F%8E%A8;Zero+installation+required+%E2%9C%A8;Just+fork%2C+click%2C+and+code+%F0%9F%92%BB)](https://git.io/typing-svg)

<br/>

<!-- BADGES ROW 1 - ANIMATED STATUS -->
[![CI Build](https://img.shields.io/github/actions/workflow/status/CloudCompile/fastvm/build-images.yml?branch=main&style=for-the-badge&logo=github-actions&logoColor=white&label=CI%20BUILD&color=6366f1)](https://github.com/CloudCompile/fastvm/actions)
[![Docker Pulls](https://img.shields.io/badge/IMAGES-14%20VARIANTS-10b981?style=for-the-badge&logo=docker&logoColor=white)](https://github.com/CloudCompile/fastvm/pkgs/container/fastvm)
[![License](https://img.shields.io/badge/LICENSE-MIT-f59e0b?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE)
[![Stars](https://img.shields.io/github/stars/CloudCompile/fastvm?style=for-the-badge&logo=starship&logoColor=white&color=ef4444&label=STARS)](https://github.com/CloudCompile/fastvm/stargazers)

<!-- BADGES ROW 2 - TECH STACK -->
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20Jammy-E95420?style=flat-square&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Docker](https://img.shields.io/badge/Docker-Powered-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docker.com)
[![KasmVNC](https://img.shields.io/badge/KasmVNC-Streaming-00B388?style=flat-square&logo=googlechrome&logoColor=white)](https://kasmweb.com)
[![GitHub Codespaces](https://img.shields.io/badge/GitHub-Codespaces-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/features/codespaces)
[![Node.js](https://img.shields.io/badge/Dashboard-Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org)

<br/>

> **Transform your browser into a complete Linux desktop environment.**  
> No downloads. No installs. No config. Just fork → open Codespace → run one command → 🖥️

<br/>

```
┌─────────────────────────────────────────────────┐
│  🌐 Browser  →  KasmVNC  →  Full Linux Desktop  │
│       (Port 3000)          (Ubuntu 22.04)       │
└─────────────────────────────────────────────────┘
```

</div>

---

## ⚡ Deploy in 30 Seconds

```bash
# 🔥 Fastest setup ever — paste this and open localhost:3000
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest
```

> Open **http://localhost:3000** → full Linux desktop, ready to use. That's it. ✨

<div align="center">

### 📊 **Deployment Timeline**

```
┌──────────────┬──────────────┬──────────────┬──────────┐
│  Download    │   Extract    │    Init      │  Ready   │
│    ~5s       │     ~5s      │    ~20s      │  Ready!  │
└──────────────┴──────────────┴──────────────┴──────────┘
0s             5s             10s            30s       🎉
```

### ⚙️ **What's Happening**
- 🐳 **Docker image pulled** (~400 MB zstd-compressed)
- 🚀 **Container starts** with optimized layer caching
- 🎨 **Desktop environment loaded** (XFCE4 by default)
- 📊 **Dashboard listening** on port 3001
- ✅ **Health checks passing** — system ready to go

</div>

---

## 🌟 Feature Showcase

<div align="center">

### **Core Features**

| 🚀 | 🎨 | ☁️ | 💾 |
|:----:|:----:|:----:|:----:|
| **Instant Deploy** | **7 Desktops** | **Cloud Native** | **Persistent** |
| 14 prebuilt images | XFCE4, KDE, GNOME | Codespaces ready | Survives restarts |
| Live in 30–60s | Cinnamon, LXQT | Zero local setup | `./data/` mount |
| Parallel CI/CD | i3, Budgie | Scales anywhere | Auto-backup |

<br/>

### **Advanced Capabilities**

```
🔧 CONFIGURATION      📊 MONITORING        🎮 GAMING          📹 MEDIA
├─ config.env         ├─ Live Dashboard   ├─ Wine support    ├─ Screen Record
├─ 5 presets          ├─ CPU/RAM graphs   ├─ Steam ready     ├─ Audio forward
├─ Per-app toggles    ├─ System metrics   ├─ 32-bit libs     ├─ ffmpeg codec
└─ Custom scripts     └─ WebSocket stream └─ Games run fast  └─ MP4/WebM out
```

<br/>

| 🔊 | 📦 | ↔️ | 📈 |
|:----:|:----:|:----:|:----:|
| **Audio Support** | **Snapshots** | **Clipboard Sync** | **Autoscaling** |
| PulseAudio + browser | One-cmd backup | Bidirectional sync | CPU/RAM monitor |
| Full mic forwarding | Instant restore | Host ↔ Desktop | Auto-adjusts |
| System + app audio | Point-in-time | X11 + xclip | Scales to load |

</div>

---

## 📦 Prebuilt Images

<div align="center">

### **14 Ready-to-Use Variants** — Pick Your Desktop

| | **Standard** | **⚡ Fast** | Performance |
|:---:|:---|:---|:---:|
| 🏃 | `ghcr.io/.../xfce4-latest` | `xfce4-fast-latest` ← _⭐ START HERE_ | 🟢 500M |
| 👑 | `ghcr.io/.../kde-latest` | `kde-fast-latest` | 🟡 2.5G |
| 🍒 | `ghcr.io/.../gnome-latest` | `gnome-fast-latest` | 🔴 2.8G |
| 🎨 | `ghcr.io/.../cinnamon-latest` | `cinnamon-fast-latest` | 🟡 2.3G |
| 🪶 | `ghcr.io/.../lxqt-latest` | `lxqt-fast-latest` | 🟢 1.5G |
| ⌨️ | `ghcr.io/.../i3-latest` | `i3-fast-latest` | 🟢 1.2G |
| 🎯 | `ghcr.io/.../budgie-latest` | `budgie-fast-latest` | 🟢 1.8G |

**Registry:** `ghcr.io/cloudcompile/fastvm`

### **Quick Pull Commands**
```bash
# 🚀 Absolute fastest (XFCE4 minimal)
docker pull ghcr.io/cloudcompile/fastvm:xfce4-fast-latest

# 🎨 Lightweight + visual (LXQT)
docker pull ghcr.io/cloudcompile/fastvm:lxqt-fast-latest

# 👑 Full-featured (KDE standard)
docker pull ghcr.io/cloudcompile/fastvm:kde-latest
```

</div>

<details>
<summary><b>⚡ Fast vs Standard — detailed comparison</b></summary>

<div align="center">

```
╔════════════════════╦═══════════════════════╦═══════════════════════╗
║    Dimension       ║     🔵 Standard       ║    ⚡ Fast (Minimal)  ║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Apps Included      ║ Full suite (Wine,     ║ Terminal + Browser    ║
║                    ║ Chrome, Steam, VLC)   ║ only — maximize speed ║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Audio System       ║ ✅ PulseAudio enabled ║ ❌ Disabled (save 50M)║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Screen Recording   ║ ✅ ffmpeg ready       ║ ❌ Disabled (save 80M)║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Backup/Snapshots   ║ ✅ Built-in tools     ║ ❌ Manual only        ║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Docker Image       ║ ~2.5 GB               ║ ~1.7 GB (-32% size)   ║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Startup Time       ║ ~60 seconds 🐢        ║ ~30 seconds 🚀        ║
╠════════════════════╬═══════════════════════╬═══════════════════════╣
║ Best For           ║ • Desktop work        ║ • Quick dev tasks     ║
║                    ║ • Long sessions       ║ • Low-spec machines   ║
║                    ║ • Streaming content   ║ • Speed-critical work ║
╚════════════════════╩═══════════════════════╩═══════════════════════╝
```

**💡 Choose Fast if:** You just need a terminal & browser, running on 2-core machine, or want instant startup.

**💡 Choose Standard if:** You need audio, recording, backups, or planning extended work sessions.

</div>

</details>

---

## 🚀 Full Setup (GitHub Codespaces)

<details open>
<summary><b>Step-by-step visual guide</b></summary>

<div align="center">

### **Setup Flow**
```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌────────────┐      ┌──────────────┐
│ 1️⃣  Fork     │  →   │ 2️⃣  Codespace │  →   │ 3️⃣  Config   │  →   │ 4️⃣  Install  │  →   │ 5️⃣  🖥️  Open   │
│   This Repo  │      │   Create       │      │   (Optional) │      │   30s–2min │      │   Desktop    │
└─────────────┘      └──────────────┘      └─────────────┘      └────────────┘      └──────────────┘
```

</div>

### **📋 Detailed Steps**

#### 1️⃣ **Fork this Repository**
Click **Fork** at the top of this page. Your settings and files live in your fork.

```
GitHub.com/CloudCompile/fastvm  →  Your-GitHub/fastvm
```

---

#### 2️⃣ **Open in Codespace**
```
Click: Code  →  Codespaces  →  Create codespace on main
```
> 💡 **Machine size?** Pick **4-core / 16 GB** for smooth experience.  
> ✅ XFCE4 works fine on 2-core if needed.

---

#### 3️⃣ **(Optional) Customize `config.env`**

Edit these lines to match your preference:

```bash
# Timezone for system clock
FASTVM_TZ=America/New_York

# Pick your desktop: XFCE4 (default) | KDE | GNOME | Cinnamon | LXQT | i3 | Budgie
FASTVM_DE=XFCE4

# Preset: none | minimal | gaming | development | office | content-creation
FASTVM_PRESET=minimal

# Toggle individual apps
FASTVM_APP_CHROME=true        # ✅ Browser
FASTVM_APP_WINE=false         # Windows app support
FASTVM_PROG_AUDIO=true        # Sound system
FASTVM_PROG_RECORDING=true    # Screen recording
```

---

#### 4️⃣ **Run the Installer**

```bash
chmod +x fastvm-install.sh && ./fastvm-install.sh
```

<div align="center">

| First Build | Subsequent Starts | Rebuild |
|:---:|:---:|:---:|
| ☕ 5–15 min | 🚀 ~30s | 📦 2–5 min |
| (Downloads ~2 GB) | (Hot cache) | (Layer cache) |

</div>

---

#### 5️⃣ **Open Your Desktop** 

Go to the **Ports tab** in Codespace → click 🌐 next to **port 3000**

```
http://localhost:3000  →  Full Linux desktop in your browser
```

**You'll see a beautiful Linux desktop. 🎉**

---

### **What's Installing**
```
✅ Desktop Environment (XFCE4 / KDE / GNOME / etc.)
✅ Applications (Wine, Chrome, VLC, Steam, etc.)
✅ Audio System (PulseAudio)
✅ Recording (ffmpeg)
✅ Dashboard (Node.js UI on port 3001)
✅ Scripts (Backup, clipboard sync, autoscaling)
```

</details>

---

## 🎛️ Desktop Environments — Choose Your Flavor

<div align="center">

### **7 Options — From Ultralight to Feature-Rich**

```
┌──────────────────────────────────────────────────────────────────┐
│  Weight Spectrum                                                 │
│  Ultralight ════════════════════════════════════ Feature-Rich    │
│     🪶       ⌨️      🏃      🎯     🎨      🍒      👑         │
│    LXQT     i3     XFCE4   Budgie Cinnamon GNOME  KDE Plasma    │
└──────────────────────────────────────────────────────────────────┘
```

| Desktop | RAM | Storage | Speed | Best For | Vibe |
|:---:|:---:|:---:|:---:|:---|:---|
| 🏃 **XFCE4** | 512 MB | ~800 MB | ⚡⚡⚡ | ⭐ **Default** — balanced & quick | 2010s comfort |
| 👑 **KDE** | 1.5 GB | ~1.8 GB | ⚡⚡ | Power users, customization | Feature-packed |
| 🍒 **GNOME** | 2 GB | ~2.1 GB | ⚡ | Modern, macOS-like feel | Sleek & modern |
| 🎨 **Cinnamon** | 1 GB | ~1.3 GB | ⚡⚡⚡ | Windows users, familiar | Traditional comfort |
| 🪶 **LXQT** | 256 MB | ~1.2 GB | ⚡⚡⚡⚡ | 2-core machines, minimal | Lightweight pro |
| ⌨️ **i3** | 128 MB | ~900 MB | ⚡⚡⚡⚡⚡ | Keyboard junkies, tiling | Power-user tiling |
| 🎯 **Budgie** | 512 MB | ~1.4 GB | ⚡⚡⚡⚡ | Clean & minimal | Linux-designed |

### **Memory vs Speed Trade-off**
```
Lowest Memory                                    Richest Experience
    i3 (128M)                                      KDE Plasma (1.5G)
    LXQT (256M)              XFCE4 (512M)        GNOME (2G)
    Budgie (512M)                  Cinnamon (1G)

Speed: i3 > LXQT > Budgie = XFCE4 > Cinnamon > GNOME > KDE
```

</div>

---

## 🎮 Presets — Auto-Configure Everything

Edit `FASTVM_PRESET=` in `config.env` to get a pre-configured environment:

<div align="center">

```
Set FASTVM_PRESET=<name>  →  Entire app stack configured automatically
```

</div>

| 🏗️ **Preset** | 📦 **What You Get** | 🎯 **Best For** | ⚡ **Startup** |
|:---|:---|:---|:---:|
| `none` | Bare desktop only | Start from scratch | 🚀 30s |
| `minimal` | Terminal + browser | Speed + essentials | 🚀 30s |
| `gaming` | **Steam** • Wine • Lutris • Game tools | 🎮 Gaming | ⚡ 90s |
| `development` | **VSCodium** • Git • Node • Docker • Tools | 👨‍💻 Coding | ⚡ 120s |
| `office` | **LibreOffice** • Calc • Writer • Browser | 📊 Office work | ⚡ 90s |
| `content-creation` | **GIMP** • Blender • VLC • Audacity • ffmpeg | 🎬 Media | ⚡ 150s |

### **Preset Configuration**
```bash
# In config.env, choose one:
FASTVM_PRESET=none                  # Completely empty
FASTVM_PRESET=minimal               # ← Fast + lean
FASTVM_PRESET=gaming                # ← For gaming
FASTVM_PRESET=development           # ← For coding
FASTVM_PRESET=office                # ← For docs
FASTVM_PRESET=content-creation      # ← For media
```

**Plus:** Each preset respects individual toggles — e.g., `FASTVM_PRESET=gaming` + `FASTVM_APP_WINE=false` will install games but skip Wine.

---

## 🐳 Container Management

<div align="center">

### **Common Operations**

</div>

```bash
# ┌─ START / STOP ───────────────────────────────────────────┐
# │                                                          │
docker-compose up -d            # 🚀 Start FastVM
docker-compose stop             # ⏸️  Stop (data preserved in ./data/)
docker-compose restart          # 🔄 Restart FastVM
docker-compose down             # 🗑️  Remove container (data still safe)
# │                                                          │
# └──────────────────────────────────────────────────────────┘

# ┌─ MONITORING ──────────────────────────────────────────────┐
# │                                                          │
docker-compose logs -f          # 📊 Live logs (press Ctrl+C to exit)
docker ps                       # 📋 List running containers
docker ps -a                    # 📋 Including stopped containers
# │                                                          │
# └──────────────────────────────────────────────────────────┘

# ┌─ UPDATES ────────────────────────────────────────────────┐
# │                                                          │
git pull                        # 📥 Get latest changes
docker-compose build            # 🔨 Rebuild with cache
docker-compose build --no-cache # 🔨 Force rebuild everything
docker-compose up -d            # ▶️  Start with new image
# │                                                          │
# └──────────────────────────────────────────────────────────┘

# ┌─ SNAPSHOTS / BACKUPS ─────────────────────────────────────┐
# │                                                          │
./scripts/backup-create.sh      # 📸 Create snapshot now
./scripts/backup-list.sh        # 📋 List all snapshots
./scripts/backup-restore.sh <f> # ♻️  Restore from snapshot
# │                                                          │
# └──────────────────────────────────────────────────────────┘

# ┌─ DASHBOARD ACCESS ────────────────────────────────────────┐
# │ Open http://localhost:3001 in your browser              │
cat data/dashboard.token        # 🔐 Copy auth token
# │ Use as: ?token=<paste-here>  or  Authorization header  │
# │                                                          │
# └──────────────────────────────────────────────────────────┘
```

---

## 🖥️ Machine Size Guide

<div align="center">

### **Pick Your Hardware**

```
CPU          Memory      Desktop Choice           Experience
─────────────────────────────────────────────────────────────
2-core    +   8 GB     XFCE4, LXQT only        ✅ Works
                        (Avoid heavy apps)      Minimal

4-core    +   16 GB    XFCE4, KDE, Cinnamon   ✅ RECOMMENDED
                        (Most apps work well)   Great balance

8-core    +   32 GB    Any desktop             ✅ Perfect
                        (No limitations)        Butter smooth
```

### **Performance Tuning**

```bash
# In config.env, if running on low-spec machines:
FASTVM_DE=XFCE4                     # Choose lightweight desktop
FASTVM_SHM_SIZE=2gb                 # Shared memory for audio
FASTVM_PRESET=minimal               # Disable heavy features

# If you have beefy hardware:
FASTVM_DE=KDE                       # Full-featured desktop
FASTVM_SHM_SIZE=8gb                 # Extra memory for smooth experience
FASTVM_PRESET=development           # All tools available
```

</div>

---

## 🛠️ Troubleshooting Guide

<details>
<summary><b>❌ Port 3000 not loading / page blank</b></summary>

**What to do:**
1. ⏱️ Wait **60 seconds** after install (building takes time)
2. 🔄 Refresh the page (Ctrl+R or Cmd+R)
3. 📊 Check container status:

```bash
# Is it running?
docker ps             # should show fastvm container as "Up"

# What went wrong?
docker-compose logs   # read error messages

# Still broken?
docker-compose restart
```

</details>

<details>
<summary><b>🐢 Desktop feels slow / laggy</b></summary>

**Solutions in order:**

```bash
# 1️⃣ Check your Codespace size
#    → Upgrade to 4-core machine (GitHub Codespaces settings)

# 2️⃣ Switch to lightweight desktop
#    Edit config.env:
FASTVM_DE=XFCE4        # Instead of KDE/GNOME
FASTVM_PRESET=minimal  # Instead of development/gaming

# 3️⃣ Increase shared memory
FASTVM_SHM_SIZE=4gb    # Add this to config.env

# 4️⃣ Rebuild and restart
docker-compose down && ./fastvm-install.sh
```

</details>

<details>
<summary><b>🔒 Permission denied on ./data/ folder</b></summary>

```bash
# Fix permissions (one-time):
sudo chown -R 1000:1000 ./data

# Or just make it world-writable:
chmod -R 755 ./data
```

</details>

<details>
<summary><b>💥 Build failed during docker-compose build</b></summary>

**Nuclear option** (full clean rebuild):

```bash
# Stop everything
docker-compose down

# Remove old image to force full rebuild
docker rmi ghcr.io/cloudcompile/fastvm:local

# Rebuild from scratch (no cache)
docker-compose build --no-cache

# Start fresh
docker-compose up -d

# Watch progress
docker-compose logs -f
```

</details>

<details>
<summary><b>⚙️ Config changes (config.env) not taking effect</b></summary>

**Config only applies on fresh container start:**

```bash
# Don't just restart — actually rebuild:
docker-compose down
./fastvm-install.sh

# This reloads config.env and applies all settings
```

**Common misses:**
- Changed `FASTVM_DE`? Needs full rebuild.
- Changed `FASTVM_PRESET`? Needs rebuild.
- Changed `FASTVM_APP_*`? Needs rebuild.

✅ **Only these DON'T need rebuild:** `FASTVM_TZ`, `FASTVM_DASHBOARD_PORT`

</details>

<details>
<summary><b>🌐 Running on local Docker (not Codespaces)?</b></summary>

```bash
# After editing config.env:
docker-compose build
docker-compose up -d

# Open in browser:
http://localhost:3000

# Check logs:
docker-compose logs -f

# Access dashboard:
# http://localhost:3001
# Token: cat data/dashboard.token
```

</details>

---

## 📁 Project Structure

<div align="center">

### **Directory Layout**

</div>

```
fastvm/
│
├── 📋 config.env                    ← 🔴 EDIT THIS: All your settings
├── 🐳 Dockerfile.optimized          ← Multi-stage optimized build
├── 🔧 docker-compose.yml            ← Docker container definition
│
├── 🚀 fastvm-install.sh             ← One-command installer
├── ⚙️  fastvm-setup.sh              ← Desktop environment setup
├── 📦 installapps-parallel.sh       ← Install apps in parallel
│
├── 🎛️  presets/                     ← Preset configurations
│   ├── gaming/                      ← Gaming apps list
│   ├── development/                 ← Dev tools list
│   ├── office/                      ← Office apps list
│   └── content-creation/            ← Media apps list
│
├── 📊 dashboard/                    ← Node.js management UI (port 3001)
│   ├── server.js                    ← Express API server
│   ├── index.html                   ← Web frontend
│   └── api/                         ← API endpoints
│       ├── performance.js           ← CPU/RAM/Disk metrics
│       ├── recording.js             ← Screen recording control
│       ├── snapshots.js             ← Backup management
│       ├── clipboard.js             ← Clipboard sync
│       └── tasks.js                 ← Scheduled task management
│
├── 🔨 scripts/                      ← Runtime shell scripts
│   ├── lib-common.sh                ← Logging & config helpers
│   ├── audio-init.sh                ← PulseAudio initialization
│   ├── clipboard-daemon.sh          ← Bidirectional clipboard sync
│   ├── screen-recorder.sh           ← ffmpeg screen recording
│   ├── backup-*.sh                  ← Snapshot create/restore/list
│   ├── autoscale-monitor.sh         ← CPU/RAM monitoring
│   └── autoscale-adjust.sh          ← Auto resource adjustment
│
├── 🌐 installable-apps/             ← Individual app installers
│   ├── wine.sh                      ← Windows app support
│   ├── chrome.sh                    ← Google Chrome
│   ├── discord.sh                   ← Discord
│   ├── steam.sh                     ← Steam gaming platform
│   ├── minecraft.sh                 ← Minecraft launcher
│   ├── vlc.sh                       ← VLC media player
│   ├── libreoffice.sh               ← Office suite
│   ├── xarchiver.sh                 ← Archive manager
│   └── openjdk-*.sh                 ← Java runtimes
│
├── 💾 data/                         ← 📌 Persistent storage (survives restarts)
│   ├── backups/                     ← Snapshot storage
│   ├── recordings/                  ← Screen recordings
│   ├── .fastvm/                     ← FastVM config
│   ├── dashboard.token              ← Auth token
│   └── tasks.json                   ← Scheduled tasks
│
├── 📝 logs/                         ← Application logs
│   └── fastvm.log                   ← Main log file
│
├── 📦 root/                         ← KasmVNC config files
│   └── etc/cont-init.d/             ← Container init hooks
│
└── 🔄 .github/workflows/            ← Automated CI/CD
    ├── build-images.yml             ← 14 parallel Docker image builds
    └── auto-deploy.yml              ← Push to GHCR registry
```

### **Key Directories Explained**

| Dir | Purpose | Access | Notes |
|:---|:---|:---|:---|
| `data/` | Persistent storage | 📌 Survives `docker-compose down` | Backup your important files here |
| `scripts/` | Runtime operations | 🔧 Runs inside container | Used by dashboard & cron jobs |
| `dashboard/` | Web UI | 🌐 Port 3001 (port 8099 inside) | Node.js Express server |
| `presets/` | App bundles | 📦 Applied at build time | Change in config.env to apply |
| `installable-apps/` | App installers | 🏗️ Run during build | Individual shell scripts per app |

---

## 🤝 Contributing

We welcome contributions of all types! Whether it's bug fixes, new features, or documentation improvements.

### **Code Quality Standards**

```bash
# Shell scripts MUST follow these rules:
set -euo pipefail              # Error handling

# Logging (use helpers from lib-common.sh):
log_info "Message"             # ℹ️  Information
log_success "Done!"            # ✅ Success
log_warn "Warning"             # ⚠️  Warning
log_error "Failed"             # ❌ Error

# APT operations:
# → One apt-get update per Dockerfile layer (don't repeat)
# → rm -rf /var/lib/apt/lists/* after install (save space)

# Data processing:
jq -e '.field'                 # ✅ Correct: exit code aware
jq '.field' | grep "x"         # ❌ Avoid: loses exit status

# Wait operations:
# → NO unnecessary sleep! If you must wait, document WHY
# → Example: "Wait 5s for PulseAudio socket to appear"
```

### **Contribution Flow**

```
1. Fork this repo
   ↓
2. Create feature branch: git checkout -b feature/my-feature
   ↓
3. Make changes & test on multiple desktops
   ↓
4. Keep PRs focused: one feature per PR
   ↓
5. Push & open PR with clear description
   ↓
6. Address review comments
   ↓
7. Merge to main! 🎉
```

### **Testing Checklist**

Before submitting PR, verify on:
- [ ] XFCE4 (lightweight baseline)
- [ ] KDE Plasma (feature-rich desktop)
- [ ] At least one preset (gaming/dev/office)
- [ ] Build logs show no errors/warnings
- [ ] Dashboard accessible on port 3001
- [ ] Desktop loads within 60 seconds

---

<div align="center">

<!-- FOOTER WAVE -->
<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=120&section=footer&animation=fadeIn"/>

### 💝 Love FastVM?

**[⭐ Star this repo](https://github.com/CloudCompile/fastvm/stargazers)** — every star helps us reach more developers!

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=CloudCompile/fastvm&type=Date)](https://star-history.com/#CloudCompile/fastvm&Date)

</div>

### **Get Involved**

| Action | Link |
|:---:|:---|
| 🐛 | **[Report a Bug](https://github.com/CloudCompile/fastvm/issues/new?labels=bug)** |
| 💡 | **[Request a Feature](https://github.com/CloudCompile/fastvm/issues/new?labels=enhancement)** |
| 💬 | **[Join Discussions](https://github.com/CloudCompile/fastvm/discussions)** |
| 📖 | **[Read the Docs](https://github.com/CloudCompile/fastvm/wiki)** |

### **Tech Stack**

```
Built with ❤️ by CloudCompile
├─ Powered by: LinuxServer.io (baseimage-kasmvnc)
├─ Desktop:   KasmVNC (browser streaming)
├─ OS:        Ubuntu 22.04 LTS (Jammy)
├─ Runtime:   Node.js (dashboard)
├─ Container: Docker + docker-compose
└─ CI/CD:     GitHub Actions (matrix builds)
```

<br/>

<table align="center">
  <tr>
    <td align="center">
      <strong>Inspired by</strong><br/>
      <a href="https://github.com/nicehash/NiceHashQuickMiner">BlobeVM</a>
    </td>
    <td align="center">
      <strong>Uses</strong><br/>
      <a href="https://linuxserver.io">LinuxServer.io</a>
    </td>
    <td align="center">
      <strong>Streamed via</strong><br/>
      <a href="https://kasmweb.com">KasmVNC</a>
    </td>
  </tr>
</table>

<br/>

**Licensed under MIT** — see [LICENSE](LICENSE) for details

> **"Linux. In a tab. On demand. Fast."** ⚡

</div>
