<div align="center">

<!-- ANIMATED HERO BANNER -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=240&section=header&text=⚡%20FastVM%20⚡&fontSize=90&fontColor=ffffff&animation=tilt&fontAlignY=35&desc=Linux%20Desktop.%20Streamed.%20Instant.&descAlignY=55&descSize=28&descColor=c4b5fd"/>
  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=240&section=header&text=⚡%20FastVM%20⚡&fontSize=90&fontColor=ffffff&animation=tilt&fontAlignY=35&desc=Linux%20Desktop.%20Streamed.%20Instant.&descAlignY=55&descSize=28&descColor=c4b5fd"/>
</picture>

<!-- ANIMATED TYPING HIGHLIGHT -->
[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=22&duration=4000&pause=800&color=FF006E&center=true&vCenter=true&width=700&height=80&lines=⚡+Full+Linux+desktop+streaming+in+your+browser;🚀+Deploy+production-ready+images+in+30+seconds;🎨+14+prebuilt+variants+—+pick+your+desktop;💻+Zero+setup.+Just+fork+%2B+click+%2B+code;🔥+Faster+than+local+—+cloud+native+by+default)](https://git.io/typing-svg)

<br/>

<!-- STATUS BADGES ROW 1 -->
<a href="https://github.com/CloudCompile/fastvm/actions">
  <img src="https://img.shields.io/github/actions/workflow/status/CloudCompile/fastvm/build-images.yml?branch=main&style=for-the-badge&logo=github-actions&logoColor=white&label=CI%20PIPELINE&color=00d4ff&labelColor=0a0e27" alt="CI Status">
</a>
<a href="https://github.com/CloudCompile/fastvm/pkgs/container/fastvm">
  <img src="https://img.shields.io/badge/🐳%20IMAGES-14%20READY-00d4ff?style=for-the-badge&labelColor=0a0e27" alt="Docker Images">
</a>
<a href="https://github.com/CloudCompile/fastvm/blob/main/LICENSE">
  <img src="https://img.shields.io/badge/LICENSE-MIT-ff006e?style=for-the-badge&labelColor=0a0e27" alt="License">
</a>
<a href="https://github.com/CloudCompile/fastvm/stargazers">
  <img src="https://img.shields.io/github/stars/CloudCompile/fastvm?style=for-the-badge&logo=starship&logoColor=white&color=ffd60a&labelColor=0a0e27&label=⭐%20STARS" alt="GitHub Stars">
</a>

<br/>

<!-- TECH STACK BADGES -->
<a href="https://ubuntu.com"><img src="https://img.shields.io/badge/Ubuntu-22.04-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu"></a>
<a href="https://docker.com"><img src="https://img.shields.io/badge/Docker-Powered-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker"></a>
<a href="https://kasmweb.com"><img src="https://img.shields.io/badge/KasmVNC-Streaming-00B388?style=flat-square&logo=googlechrome&logoColor=white" alt="KasmVNC"></a>
<a href="https://github.com/features/codespaces"><img src="https://img.shields.io/badge/GitHub-Codespaces-181717?style=flat-square&logo=github&logoColor=white" alt="Codespaces"></a>
<a href="https://nodejs.org"><img src="https://img.shields.io/badge/Node.js-Dashboard-339933?style=flat-square&logo=nodedotjs&logoColor=white" alt="Node.js"></a>

<br/>
<br/>

> ✨ **Transform any browser into a full-featured Linux desktop environment**  
> 🚀 Fork once → Deploy anywhere → Scale infinitely  
> 💡 No local setup. No downloads. No headaches.

<br/>

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🌐  YOUR BROWSER  ━━━━━>  KasmVNC  ━━━━━>  🖥️ LINUX   ║
║    Port 3000              Streaming          Desktop      ║
║                                                            ║
║   📊 DASHBOARD  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━  🎛️ CONTROL ║
║    Port 3001              Node.js API                     ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

</div>

---

<div align="center">

### 🚀 **FASTEST WAY TO GET STARTED**

</div>

## ⚡ **Deploy in 30 Seconds** ⚡

```bash
# Copy → Paste → Open http://localhost:3000 → 🖥️ BOOM! Full Linux Desktop
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest
```

<div align="center">

### **Startup Timeline**

```
     🌐              🐳              🚀              ✅
  BROWSER         DOCKER          KASM           READY!
     │              │               │               │
     │ docker run   │ pull (~5s)    │ init (~20s)   │
     ├─────────────>├──────────────>├──────────────>│
     │              │               │               │
     0s             2s              7s             30s  🎉

🔥 Performance Breakdown:
  • Image Download  ───────────  ~5 seconds
  • Layer Extraction ──────────  ~3 seconds
  • Desktop Init ──────────────  ~20 seconds
  • Healthcheck Pass ─────────  ~2 seconds
                              ──────────────
                         TOTAL: ~30 seconds
```

### **Behind the Scenes**
```
Stage 1: 🐳  Image pulled from GHCR (zstd-compressed, ~400 MB)
Stage 2: 📦  Layers extracted with buildx cache optimization
Stage 3: 🎨  Desktop environment initialized (XFCE4 default)
Stage 4: 📊  Dashboard API server starts on :8099
Stage 5: ✅  Health check passes — system READY
```

> 💡 **Pro Tip:** Use `-fast` variants for ~30% smaller images (15-20s faster)

</div>

---

## 🌟 **Feature Powerhouse** 🌟

<div align="center">

### **⚡ Headline Features**

```
╔═══════════════════╦═══════════════════╦═══════════════════╦═══════════════════╗
║     🚀 SPEED      ║     🎨 CHOICE     ║      ☁️ CLOUD     ║      💾 DATA      ║
╠═══════════════════╬═══════════════════╬═══════════════════╬═══════════════════╣
║  30-second start  ║  7 desktop envs   ║  Codespaces ready ║  Survives restarts║
║  14 prebuilt imgs ║  Pick your style  ║  Deploy anywhere  ║  Auto-snapshots   ║
║  Parallel builds  ║  Lightweight+full ║  Infinite scaling ║  Point-in-time    ║
║  Layer caching    ║  XFCE→KDE→GNOME  ║  Zero local setup ║  Full backup tool ║
╚═══════════════════╩═══════════════════╩═══════════════════╩═══════════════════╝
```

<br/>

### **🔥 Advanced Toolkit**

```
┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┓
┃ ⚙️  CONFIG      ┃ 📊 MONITOR       ┃ 🎮 GAMING        ┃ 🎬 MEDIA         ┃
┣━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━┫
┃ • config.env     ┃ • Live Dashboard ┃ • Wine (x86-64)  ┃ • Screen Record  ┃
┃ • 5 presets      ┃ • CPU/RAM graphs ┃ • Steam support  ┃ • Audio forward  ┃
┃ • Per-app toggle ┃ • Disk metrics   ┃ • GPU access     ┃ • ffmpeg ready   ┃
┃ • Custom scripts ┃ • Real-time push ┃ • Game servers   ┃ • MP4/WebM codec ┃
┗━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━┛

┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┓
┃ 🔊 AUDIO        ┃ 📦 BACKUP        ┃ ↔️  SYNC          ┃ 📈 AUTOSCALE     ┃
┣━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━┫
┃ • PulseAudio     ┃ • One-cmd backup ┃ • Bidirectional  ┃ • CPU monitoring ┃
┃ • Browser audio  ┃ • Instant restore┃ • Host ↔ Desktop ┃ • RAM tracking   ┃
┃ • Mic forward    ┃ • Point-in-time  ┃ • X11 + xclip    ┃ • Auto-adjust    ┃
┃ • System sound   ┃ • Scheduled auto ┃ • Zero-lag sync  ┃ • Load-aware     ┃
┗━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━┛
```

</div>

---

## 📦 **14 Production-Ready Images** 📦

<div align="center">

### **Pre-Built Variants — Deploy in Seconds**

```
🌐 REGISTRY: ghcr.io/cloudcompile/fastvm
```

<br/>

| | **LIGHTWEIGHT** ⚡ | **STANDARD** 🔧 | **SIZE** | **STARTUP** |
|:---:|:---|:---|:---:|:---:|
| 🏃 **XFCE4** | `xfce4-fast-latest` ⭐ | `xfce4-latest` | 1.5 GB | 30s |
| 👑 **KDE Plasma** | `kde-fast-latest` | `kde-latest` | 2.5 GB | 60s |
| 🍒 **GNOME** | `gnome-fast-latest` | `gnome-latest` | 2.8 GB | 75s |
| 🎨 **Cinnamon** | `cinnamon-fast-latest` | `cinnamon-latest` | 2.3 GB | 65s |
| 🪶 **LXQT** | `lxqt-fast-latest` | `lxqt-latest` | 1.2 GB | 25s |
| ⌨️ **i3** | `i3-fast-latest` | `i3-latest` | 1.1 GB | 20s |
| 🎯 **Budgie** | `budgie-fast-latest` | `budgie-latest` | 1.8 GB | 45s |

<br/>

### **🚀 Quick Start Commands**

```bash
# ⚡ FASTEST — Minimal XFCE4 (recommended for beginners)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest

# 🪶 ULTRALIGHT — LXQT (best for 2-core machines)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-fast-latest

# ⌨️  MINIMALIST — i3 tiling (for keyboard warriors)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-fast-latest

# 👑 FULL-FEATURED — KDE Plasma (all the bells & whistles)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-latest

# 🍒 MODERN — GNOME 43+ (sleek & powerful)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-latest
```

> **Then open:** `http://localhost:3000` in your browser ✨

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

## 🚀 **Setup Guide** 🚀

<details open>
<summary><b>5-Step Activation Sequence</b></summary>

<div align="center">

### **Deployment Pipeline**

```
  1️⃣  FORK          2️⃣  CODESPACE       3️⃣  CONFIG        4️⃣  INSTALL       5️⃣  LAUNCH
  ─────────────    ──────────────────   ──────────────   ─────────────────  ─────────────
  Fork this repo   Create in GitHub     Edit config.env  Run installer      Open desktop
  (GitHub.com)     (2-4 core / 8-16GB)  (2 minutes)      (5-15 minutes)     (30 seconds)
     │                  │                    │                 │                  │
     ├──────────────────┤──────────────────┬─┤─────────────────┤──────────────────┤
     │   Your Fork       │                  │ │  Building       │                  │
     │  Ready to Go      │ Infrastructure   │ │  Container      │ 🖥️ LINUX READY  │
     │                   │   Deployed       │ │  in Progress    │                  │
     ▼                   ▼                  ▼ ▼                 ▼                  ▼
  5 seconds         1-2 minutes        2 minutes      5-15 minutes      ~30 seconds total

═════════════════════════════════════════════════════════════════════════════════════════════════
     FAST LANE: Already have Docker locally? Skip Codespaces → go to Docker quick start
═════════════════════════════════════════════════════════════════════════════════════════════════
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

## 🎛️ **Choose Your Desktop** 🎛️

<div align="center">

### **7 Desktop Environments — Pick Your Vibe**

```
ULTRALIGHT ZONE          │        BALANCED ZONE         │      FEATURE-RICH ZONE
═════════════════════════╪═════════════════════════════╪═════════════════════════
🪶 LXQT                  │ 🏃 XFCE4 ⭐               │ 👑 KDE Plasma
⌨️  i3 (tiling)         │ 🎯 Budgie                 │ 🍒 GNOME 43+
128MB RAM               │ 512MB RAM                  │ 2GB RAM
20-25s startup          │ 30-45s startup             │ 60-75s startup
Minimal, lean           │ Default, balanced          │ Full, beautiful
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

## 🎮 **Preset Environments** 🎮

<div align="center">

### **One-Line Setup for Any Workflow**

```bash
FASTVM_PRESET=<name>  ─────>  Entire app stack auto-configured
```

</div>

```
┏━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━┓
┃  PRESET    ┃        INCLUDES               ┃   USE FOR   ┃  BUILD    ┃
┣━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━┫
┃  none      ┃  Bare desktop only           ┃  Custom     ┃  🚀 30s   ┃
┃  minimal   ┃  Terminal + Browser          ┃  Speed      ┃  🚀 30s   ┃
┃  gaming    ┃  🎮 Steam + Wine + Lutris   ┃  Gaming     ┃  ⚡ 90s   ┃
┃  dev       ┃  💻 VSCodium + Git + Node   ┃  Coding     ┃  ⚡ 120s  ┃
┃  office    ┃  📊 LibreOffice + Calc      ┃  Office     ┃  ⚡ 90s   ┃
┃  media     ┃  🎬 GIMP + VLC + Audacity   ┃  Creation   ┃  ⚡ 150s  ┃
┗━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━┛
```

### **Configuration in `config.env`**

```bash
# Uncomment and choose one preset:
FASTVM_PRESET=minimal               # ← Recommended for speed
# FASTVM_PRESET=gaming
# FASTVM_PRESET=development
# FASTVM_PRESET=office
# FASTVM_PRESET=content-creation

# 💡 PRO TIP: Presets + individual toggles stack!
# Example: gaming preset WITHOUT Wine:
FASTVM_PRESET=gaming
FASTVM_APP_WINE=false               # Override individual apps
```

**Extra:** Mix & match — toggle individual apps on top of any preset. Presets are just smart defaults!

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

<!-- ANIMATED FOOTER WAVE -->
<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=150&section=footer&animation=tilt"/>

<br/>

### 🌟 **Join the Community** 🌟

```
"Linux in a Tab. Instant. Instant. Instant."
                    — FastVM
```

<br/>

<h3>
  <a href="https://github.com/CloudCompile/fastvm/stargazers">
    ⭐ STAR THIS REPO
  </a>
  &nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/CloudCompile/fastvm/issues/new?labels=bug">
    🐛 REPORT BUG
  </a>
  &nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/CloudCompile/fastvm/issues/new?labels=enhancement">
    💡 SUGGEST FEATURE
  </a>
  &nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/CloudCompile/fastvm/discussions">
    💬 DISCUSS
  </a>
</h3>

<br/>

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                  ┃
┃  🚀 FastVM — Linux Desktop as a Service                        ┃
┃                                                                  ┃
┃  ✨ Built with ❤️  by CloudCompile                             ┃
┃  🐳 Powered by LinuxServer.io + KasmVNC + Node.js              ┃
┃  🔧 Orchestrated by Docker + GitHub Actions                    ┃
┃  📦 Running Ubuntu 22.04 LTS (Jammy) in production             ┃
┃                                                                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

<br/>

### **Stack & Attribution**

| Component | Technology | Link |
|:---:|:---|:---|
| 🖼️ **Base Image** | LinuxServer.io baseimage-kasmvnc | [linuxserver.io](https://linuxserver.io) |
| 🌐 **Streaming** | KasmVNC (browser-native remote desktop) | [kasmweb.com](https://kasmweb.com) |
| 🖥️ **OS** | Ubuntu 22.04 LTS (Jammy) | [ubuntu.com](https://ubuntu.com) |
| 🔧 **Backend** | Node.js Express API + Dashboard | [nodejs.org](https://nodejs.org) |
| 🐳 **Container** | Docker + docker-compose | [docker.com](https://docker.com) |
| 🤖 **CI/CD** | GitHub Actions (matrix parallel builds) | [github.com/features/actions](https://github.com/features/actions) |

<br/>

---

<br/>

**📜 Licensed under [MIT](LICENSE)** — Use freely, modify, share, commercialize.

> **FastVM** transforms container orchestration into instant desktop infrastructure.  
> Deploy once → Use anywhere → Scale infinitely. ⚡

<br/>

```
 ___  ___    _    ___  ___   ____  ___       ____  _____  _   _  __ __ 
|  _||__ \  / \  / __|/ __|  |__  |  |     / _  |/  __/ | | | |  |  |
| |_   / / / _ \ \___ \\___ \    / /  |  |    |  \_|\___ \  | |_| | _\| |_
|___| |__//_/ \_\|___/|___/   |__| |__||    \___/|____/   \___/|_|    |_|
                                                                        
```

</div>
