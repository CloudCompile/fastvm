<div align="center">

<!-- HERO BANNER -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=200&section=header&text=FastVM&fontSize=80&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=Linux%20Desktop.%20In%20a%20Tab.&descAlignY=55&descSize=24&descColor=c4b5fd"/>
  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=200&section=header&text=FastVM&fontSize=80&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=Linux%20Desktop.%20In%20a%20Tab.&descAlignY=55&descSize=24&descColor=c4b5fd"/>
</picture>

<!-- TYPING ANIMATION -->
[![Typing SVG](https://readme-typing-svg.demolab.com?font=JetBrains+Mono&size=18&pause=1000&color=6366F1&center=true&vCenter=true&width=600&lines=Full+Linux+desktop+in+your+browser+%E2%9A%A1;Deploy+in+30+seconds+with+prebuilt+images+%F0%9F%9A%80;7+desktop+environments+to+choose+from+%F0%9F%8E%A8;Zero+installation+required+%E2%9C%A8;Just+fork%2C+click%2C+and+code+%F0%9F%92%BB)](https://git.io/typing-svg)

<br/>

<!-- BADGES ROW 1 -->
[![CI Build](https://img.shields.io/github/actions/workflow/status/CloudCompile/fastvm/build-images.yml?branch=main&style=for-the-badge&logo=github-actions&logoColor=white&label=CI%20BUILD&color=6366f1)](https://github.com/CloudCompile/fastvm/actions)
[![Docker Pulls](https://img.shields.io/badge/IMAGES-14%20VARIANTS-10b981?style=for-the-badge&logo=docker&logoColor=white)](https://github.com/CloudCompile/fastvm/pkgs/container/fastvm)
[![License](https://img.shields.io/badge/LICENSE-MIT-f59e0b?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE)
[![Stars](https://img.shields.io/github/stars/CloudCompile/fastvm?style=for-the-badge&logo=starship&logoColor=white&color=ef4444&label=STARS)](https://github.com/CloudCompile/fastvm/stargazers)

<!-- BADGES ROW 2 -->
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20Jammy-E95420?style=flat-square&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Docker](https://img.shields.io/badge/Docker-Powered-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docker.com)
[![KasmVNC](https://img.shields.io/badge/KasmVNC-Streaming-00B388?style=flat-square&logo=googlechrome&logoColor=white)](https://kasmweb.com)
[![GitHub Codespaces](https://img.shields.io/badge/GitHub-Codespaces-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/features/codespaces)
[![Node.js](https://img.shields.io/badge/Dashboard-Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org)

<br/>

> **Transform your browser into a complete Linux desktop environment.**  
> No downloads. No installs. No config. Just fork → open Codespace → run one command → 🖥️

<br/>

</div>

---

## ⚡ Deploy in 30 Seconds

```bash
# 🔥 Fastest setup ever — paste this and open localhost:3000
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest
```

> Open **http://localhost:3000** → full Linux desktop, ready to use. That's it. ✨

---

## 🌟 Feature Highlights

<div align="center">

| | Feature | Details |
|---|---|---|
| ⚡ | **Instant Deploy** | 14 prebuilt images, live in 30–60s |
| 🎨 | **7 Desktops** | XFCE4, KDE, GNOME, Cinnamon, LXQT, i3, Budgie |
| ☁️ | **Cloud Native** | Runs in GitHub Codespaces, zero local setup |
| 💾 | **Persistent** | Files survive restarts via `./data/` mount |
| 🔧 | **Fully Customizable** | `config.env` controls everything |
| 📊 | **Live Dashboard** | Built-in Node.js management UI on port 3001 |
| 🔊 | **Audio Support** | PulseAudio + browser audio forwarding |
| 📹 | **Screen Recording** | Built-in ffmpeg recording |
| 📦 | **Snapshots** | One-command backup/restore |
| ↔️ | **Clipboard Sync** | Bidirectional clipboard between host and desktop |
| 📈 | **Autoscaling** | CPU/RAM monitoring with automatic adjustments |
| 🎮 | **Presets** | Gaming, Dev, Office, Content-Creation, Minimal |

</div>

---

## 📦 Prebuilt Images

<div align="center">

### Pull any image → desktop ready in seconds

| Desktop | Standard | ⚡ Fast (Recommended) |
|:-------:|:--------:|:--------------------:|
| 🏃 **XFCE4** | `xfce4-latest` | `xfce4-fast-latest` ← _start here_ |
| 👑 **KDE** | `kde-latest` | `kde-fast-latest` |
| 🍒 **GNOME** | `gnome-latest` | `gnome-fast-latest` |
| 🎨 **Cinnamon** | `cinnamon-latest` | `cinnamon-fast-latest` |
| 🪶 **LXQT** | `lxqt-latest` | `lxqt-fast-latest` |
| ⌨️ **i3** | `i3-latest` | `i3-fast-latest` |
| 🎯 **Budgie** | `budgie-latest` | `budgie-fast-latest` |

**Registry:** `ghcr.io/cloudcompile/fastvm:<tag>`

</div>

<details>
<summary><b>⚡ Fast vs Standard — what's the difference?</b></summary>

| | Standard | ⚡ Fast |
|---|---|---|
| Apps | Full (Wine, Chrome, extras) | Minimal (terminal + browser) |
| Audio | ✅ | ❌ |
| Recording | ✅ | ❌ |
| Backups | ✅ | ❌ |
| Image size | ~2.5 GB | ~1.7 GB |
| Startup | ~60s | **~30s** |

Fast images are perfect for quick tasks, development, or low-spec machines.

</details>

---

## 🚀 Full Setup (GitHub Codespaces)

<details open>
<summary><b>Step-by-step guide</b></summary>

### 1️⃣ Fork this repo

Click **Fork** at the top of this page. Your settings and files live in your fork.

### 2️⃣ Open in Codespace

**Code → Codespaces → Create codespace on main**

> 💡 Pick **4-core / 16 GB** for a great experience. XFCE4 works fine on 2-core.

### 3️⃣ (Optional) Edit `config.env`

```bash
FASTVM_TZ=America/New_York    # Your timezone
FASTVM_DE=XFCE4               # Desktop environment
FASTVM_PRESET=minimal         # none | minimal | gaming | development | office
FASTVM_APP_CHROME=true        # Install Chrome
FASTVM_APP_WINE=false         # Windows app support
```

### 4️⃣ Run the installer

```bash
chmod +x fastvm-install.sh && ./fastvm-install.sh
```

☕ First build takes **5–15 min** — it's downloading ~2 GB.

### 5️⃣ Open your desktop

Go to the **Ports tab** → click 🌐 next to port **3000**

**You'll see a full Linux desktop in your browser. 🎉**

</details>

---

## 🎛️ Desktop Environments

<div align="center">

| Desktop | Weight | RAM | Best For |
|:-------:|:------:|:---:|:--------:|
| 🏃 **XFCE4** | Light | 512 MB | ⭐ Default — fast & reliable |
| 👑 **KDE Plasma** | Heavy | 1.5 GB | Power users, beautiful UI |
| 🍒 **GNOME** | Heavy | 2 GB | Modern macOS-like feel |
| 🎨 **Cinnamon** | Medium | 1 GB | Windows users at home |
| 🪶 **LXQT** | Ultralight | 256 MB | 2-core machines |
| ⌨️ **i3** | Minimal | 128 MB | Keyboard-driven tiling |
| 🎯 **Budgie** | Light | 512 MB | Clean & minimal |

</div>

---

## 🎮 Presets

Edit `FASTVM_PRESET=` in `config.env` to instantly configure a full app stack:

| Preset | What's Included |
|--------|----------------|
| `none` | Bare desktop, you pick everything |
| `minimal` | Terminal + browser only, fastest startup |
| `gaming` | Steam, Wine, Lutris, game tools |
| `development` | VSCodium, Git, Docker, dev tools |
| `office` | LibreOffice, browser, productivity apps |
| `content-creation` | GIMP, VLC, recording tools |

---

## 🐳 Container Management

```bash
# ── Start / Stop ─────────────────────────────────
docker-compose up -d            # Start FastVM
docker-compose stop             # Stop (data preserved)
docker-compose restart          # Restart

# ── Monitoring ───────────────────────────────────
docker-compose logs -f          # Live logs
docker ps                       # Check status

# ── Updates ──────────────────────────────────────
git pull
docker-compose build
docker-compose up -d

# ── Snapshots ────────────────────────────────────
./backup-manager.sh create      # Snapshot now
./backup-manager.sh list        # List snapshots
./backup-manager.sh restore <f> # Restore snapshot

# ── Dashboard ────────────────────────────────────
# Open http://localhost:3001 for the management UI
cat data/dashboard.token        # Get access token
```

---

## 🖥️ Machine Size Guide

<div align="center">

| Codespace | Desktop | Experience |
|:---------:|:-------:|:----------:|
| 2-core / 8 GB | XFCE4, LXQT | ✅ Works · avoid heavy apps |
| 4-core / 16 GB | XFCE4, KDE, Cinnamon | ✅ **Recommended** |
| 8-core / 32 GB | Any | ✅ Buttery smooth |

</div>

---

## 🛠️ Troubleshooting

<details>
<summary>❌ Port not loading / page blank</summary>

Wait 60 seconds after install, then refresh. Check if it's running:
```bash
docker ps             # should show FastVM container
docker-compose logs   # see what went wrong
```
</details>

<details>
<summary>🐢 Desktop feels slow</summary>

1. Upgrade to 4-core Codespace machine
2. Switch to lighter desktop: `FASTVM_DE=XFCE4` in `config.env`
3. Add RAM: `FASTVM_SHM_SIZE=4gb`
</details>

<details>
<summary>🔒 Permission denied on data/</summary>

```bash
sudo chown -R 1000:1000 ./data
```
</details>

<details>
<summary>💥 Build failed</summary>

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```
</details>

<details>
<summary>⚙️ Config changes not taking effect</summary>

```bash
docker-compose down && ./fastvm-install.sh
```
</details>

---

## 📁 Project Structure

```
fastvm/
├── 📋 config.env              ← All your settings live here
├── 🐳 Dockerfile.optimized    ← Multi-stage optimized build
├── 🔧 docker-compose.yml      ← Container orchestration
├── 🚀 fastvm-install.sh       ← One-command installer
├── ⚙️  fastvm-setup.sh         ← Desktop environment setup
├── 📦 installapps-parallel.sh ← Parallel app installer
├── 🎛️  presets/                ← App bundles (gaming, dev, etc.)
├── 📊 dashboard/              ← Node.js management UI
│   ├── server.js              ← Express API server (port 8099)
│   ├── api/                   ← performance, recording, backup APIs
│   └── index.html             ← Dashboard frontend
├── 🔨 scripts/               ← Runtime shell scripts
│   ├── lib-common.sh          ← Shared logging helpers
│   ├── audio-init.sh          ← PulseAudio setup
│   ├── screen-recorder.sh     ← ffmpeg recording
│   ├── backup-*.sh            ← Snapshot management
│   └── autoscale-*.sh         ← CPU/RAM autoscaling
├── 💾 data/                   ← Persistent files (survives restarts)
├── 📝 logs/                   ← Application logs
└── 🔄 .github/workflows/      ← Automated CI/CD builds
```

---

## 🤝 Contributing

We welcome all contributions!

**Code standards:**
- All scripts use `set -euo pipefail`
- Log with `log_info` / `log_success` / `log_warn` / `log_error` from `lib-common.sh`
- No unnecessary `sleep` — if you wait, document why
- Use `jq -e` over `jq | grep`
- One `apt-get update` per Dockerfile layer

**To contribute:**
1. Fork → branch → code → PR
2. Test on multiple desktops if possible
3. Keep PRs focused — one thing at a time

---

<div align="center">

<!-- FOOTER WAVE -->
<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=120&section=footer&animation=fadeIn"/>

### 💝 Enjoying FastVM?

**[⭐ Give us a star](https://github.com/CloudCompile/fastvm/stargazers)** — it helps more people find this project!

[![Star History](https://img.shields.io/github/stars/CloudCompile/fastvm?style=social)](https://github.com/CloudCompile/fastvm/stargazers)

<br/>

**[🐛 Report a Bug](https://github.com/CloudCompile/fastvm/issues/new)** · **[💡 Request a Feature](https://github.com/CloudCompile/fastvm/issues/new)** · **[💬 Discussions](https://github.com/CloudCompile/fastvm/discussions)**

<br/>

Built with ❤️ by **[CloudCompile](https://github.com/CloudCompile)**

Based on [BlobeVM](https://github.com/nicehash/NiceHashQuickMiner) · Powered by [LinuxServer.io](https://linuxserver.io) · Streamed via [KasmVNC](https://kasmweb.com)

**MIT License**

</div>
