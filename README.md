<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=250&section=header&text=FastVM&fontSize=100&fontColor=ffffff&animation=tilt&fontAlignY=40&desc=Linux%20Desktop%20Streaming%20Platform&descAlignY=60&descSize=30&descColor=a78bfa"/>
  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=250&section=header&text=FastVM&fontSize=100&fontColor=ffffff&animation=tilt&fontAlignY=40&desc=Linux%20Desktop%20Streaming%20Platform&descAlignY=60&descSize=30&descColor=a78bfa"/>
</picture>

### 🎯 One Command. Full Desktop.

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Jetbrains+Mono&size=20&duration=3000&pause=1000&color=6366F1&center=true&vCenter=true&width=700&height=100&lines=⚡+Stream+a+full+Linux+desktop+in+your+browser;🚀+236+production-ready+image+variants;🎨+36+desktop+environments+to+choose+from;💻+Zero+local+setup%2C+instant+deployment;🔥+30-second+startup%2C+pure+speed)](https://git.io/typing-svg)

<br/>

### DISCORD JOIN UP
https://discord.gg/aahtG9n537

### ⚡ STATUS

<a href="https://github.com/CloudCompile/fastvm/actions"><img src="https://img.shields.io/github/actions/workflow/status/CloudCompile/fastvm/build-images.yml?branch=main&style=for-the-badge&logo=github-actions&logoColor=white&label=CI%20BUILDS&color=6366f1&labelColor=1e1b4b" alt="CI Status"></a>
<a href="https://github.com/CloudCompile/fastvm"><img src="https://img.shields.io/badge/📦%20IMAGES-236%20VARIANTS-a855f7?style=for-the-badge&labelColor=0a0e27" alt="Docker Images"></a>
<a href="https://github.com/CloudCompile/fastvm/stargazers"><img src="https://img.shields.io/github/stars/cloudcompile/fastvm?style=for-the-badge&logo=starship&logoColor=white&color=ffd60a&labelColor=0a0e27" alt="GitHub Stars"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/LICENSE-MIT-ff006e?style=for-the-badge&labelColor=0a0e27" alt="License"></a>
<a href="https://codespaces.new/CloudCompile/fastvm"><img src="https://img.shields.io/badge/OPEN%20IN-CODESPACES-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=0a0e27" alt="Open in Codespaces"></a>

<br/>

### 🔗 Tech Stack

<a href="https://ubuntu.com"><img src="https://img.shields.io/badge/Ubuntu-22.04%20Jammy-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu"></a>
<a href="https://docker.com"><img src="https://img.shields.io/badge/Docker-Latest-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker"></a>
<a href="https://kasmweb.com"><img src="https://img.shields.io/badge/KasmVNC-Streaming-00B388?style=flat-square&logo=googlechrome&logoColor=white" alt="KasmVNC"></a>
<a href="https://nodejs.org"><img src="https://img.shields.io/badge/Node.js-Dashboard-339933?style=flat-square&logo=nodedotjs&logoColor=white" alt="Node.js"></a>

</div>

---

## 📊 **Real-Time Stats**

  ```text
  ✅ Successful Builds:     2+
  📦 Published Image Variants: 236
  📝 Total Commits:         199
  🕐 Last Updated:          2026-10-15 20:06:20 UTC
  ```

  **These are real metrics** — updated every hour from actual GitHub Actions and repository data.

---

## 📊 **Built-In Analytics Dashboard**

Every FastVM instance tracks its own usage:

- **Live Session Monitoring** — See how many users are active right now
- **Uptime Tracking** — Container stability and reliability metrics
- **Session History** — Duration, frequency, and usage patterns
- **Performance Stats** — CPU, RAM, disk monitoring

**Access your stats:** `http://localhost:3001/api/analytics/stats` (after authentication)

Each deployment tracks its own metrics privately. No cloud services. No data collection. Pure local stats. 📈

---

## 🚀 **FASTEST DEPLOYMENT EVER**

```bash
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-none-latest
# ↓ Open http://localhost:3000
# ↓ BOOM 💥 Full Linux Desktop
```

Startup time depends on the host, image, and selected applications. Measure it on your deployment rather than relying on a fixed promise.

## Deployment contract

- Browser desktop: host port `3000` → container port `3000`.
- Dashboard: host port `3001` → container port `8099`.
- Runtime data is persisted under `./data`, `./backups`, `./recordings`, and `./logs`.
- `FASTVM_DE` and `FASTVM_PRESET` are build-time selections for published images; most feature toggles are runtime settings.
- Copy `config.env.example` to `config.env`, then run `scripts/validate-config.sh`.
- The dashboard token is stored in `data/dashboard.token` and is never printed to logs. Prefer the `Authorization: Bearer` header; query-string tokens are disabled by default.
- Compose uses `privileged: false` by default. Enable it only when the workload requires broad device access, and expose the service through HTTPS/authenticated proxying outside a trusted network.

See `SECURITY.md`, `docs/image-catalog.md`, `docs/benchmarks.md`, `docs/gpu.md`,
`docs/app-bundles.md`, `docs/discord-vm.md`, `docs/performance.md`, and
`docs/roadmap.md` for operational guidance.

## ☁️ **GITHUB CODESPACES**

FastVM ships a `.devcontainer/` that starts a streamed XFCE4 desktop for you.
Open the repository in a Codespace and, when the container is ready, port **3000**
opens the desktop in your browser; the dashboard is on **3001**.

The devcontainer pulls the published image (`ghcr.io/cloudcompile/fastvm:xfce4-none-latest`)
rather than building, so a fresh Codespace is ready in about a minute instead of
building the image for ~30. The installer's `--pull` fast path does the same thing
outside Codespaces:

```bash
./fastvm-install.sh --pull      # pull the image for your desktop/preset
./fastvm-install.sh --no-build  # use the image already present
./fastvm-install.sh --print-image   # show which image --pull would use
```

Change the desktop or preset by editing `FASTVM_DE` / `FASTVM_PRESET` (and
`FASTVM_IMAGE`) in `.devcontainer/devcontainer.json`. A 2-core / 8 GB Codespace
works because FastVM auto-tunes itself for small hosts (`docs/performance.md`).

The image is pulled in `onCreateCommand`, so a **prebuild** snapshots it and a
prebuilt Codespace starts with no pull at all. Codespaces has no `/dev/kvm`
(emulators run in software) and is CPU-only; FastVM detects this at start and
reports it at `/api/system/status`. See `docs/codespaces.md` for the full guide.

## 📦 **Every Deployment Option**

This is the complete, copy-paste catalog of every way to deploy FastVM. All published images live on GitHub Container Registry under `ghcr.io/cloudcompile/fastvm`. Each command is self-contained.

> **Tags:** `<desktop>-<preset>-latest` for desktop images, `<singleapp>-latest` for the ultra-minimal single-app images, and `<flavor>-latest` for distro-flavor images. Every image publishes on the browser port `3000`; the analytics dashboard listens on `8099`, so add `-p 3001:8099` when you want it.

### 1. Desktop + preset images

Every desktop below ships with all six presets: `none`, `minimal`, `gaming`, `development`, `office`, `content-creation`.

```bash
# Generic form:
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:<desktop>-<preset>-latest

# xfce4
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-content-creation-latest

# kde
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-content-creation-latest

# gnome
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-content-creation-latest

# cinnamon
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:cinnamon-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:cinnamon-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:cinnamon-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:cinnamon-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:cinnamon-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:cinnamon-content-creation-latest

# lxqt
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-content-creation-latest

# i3
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:i3-content-creation-latest

# budgie
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:budgie-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:budgie-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:budgie-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:budgie-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:budgie-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:budgie-content-creation-latest

# mate
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:mate-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:mate-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:mate-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:mate-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:mate-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:mate-content-creation-latest

# lxde
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxde-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxde-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxde-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxde-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxde-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxde-content-creation-latest

# fluxbox
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fluxbox-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fluxbox-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fluxbox-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fluxbox-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fluxbox-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fluxbox-content-creation-latest

# unity
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:unity-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:unity-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:unity-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:unity-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:unity-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:unity-content-creation-latest

# enlightenment
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:enlightenment-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:enlightenment-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:enlightenment-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:enlightenment-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:enlightenment-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:enlightenment-content-creation-latest

# icewm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:icewm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:icewm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:icewm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:icewm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:icewm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:icewm-content-creation-latest

# awesome
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:awesome-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:awesome-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:awesome-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:awesome-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:awesome-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:awesome-content-creation-latest

# ukui
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ukui-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ukui-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ukui-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ukui-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ukui-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ukui-content-creation-latest

# bspwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:bspwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:bspwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:bspwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:bspwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:bspwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:bspwm-content-creation-latest

# gnome-flashback
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-flashback-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-flashback-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-flashback-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-flashback-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-flashback-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:gnome-flashback-content-creation-latest

# wmaker
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:wmaker-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:wmaker-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:wmaker-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:wmaker-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:wmaker-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:wmaker-content-creation-latest

# herbstluftwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:herbstluftwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:herbstluftwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:herbstluftwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:herbstluftwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:herbstluftwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:herbstluftwm-content-creation-latest

# jwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:jwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:jwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:jwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:jwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:jwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:jwm-content-creation-latest

# fvwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fvwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fvwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fvwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fvwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fvwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:fvwm-content-creation-latest

# xmonad
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xmonad-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xmonad-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xmonad-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xmonad-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xmonad-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xmonad-content-creation-latest

# sugar
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sugar-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sugar-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sugar-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sugar-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sugar-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sugar-content-creation-latest

# dwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:dwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:dwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:dwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:dwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:dwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:dwm-content-creation-latest

# ratpoison
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ratpoison-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ratpoison-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ratpoison-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ratpoison-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ratpoison-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ratpoison-content-creation-latest

# blackbox
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:blackbox-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:blackbox-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:blackbox-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:blackbox-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:blackbox-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:blackbox-content-creation-latest

# pop-os
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pop-os-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pop-os-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pop-os-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pop-os-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pop-os-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pop-os-content-creation-latest

# pekwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pekwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pekwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pekwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pekwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pekwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pekwm-content-creation-latest

# spectrwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:spectrwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:spectrwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:spectrwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:spectrwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:spectrwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:spectrwm-content-creation-latest

# sawfish
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sawfish-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sawfish-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sawfish-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sawfish-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sawfish-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:sawfish-content-creation-latest

# openbox
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:openbox-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:openbox-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:openbox-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:openbox-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:openbox-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:openbox-content-creation-latest

# afterstep
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:afterstep-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:afterstep-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:afterstep-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:afterstep-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:afterstep-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:afterstep-content-creation-latest

# ctwm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ctwm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ctwm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ctwm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ctwm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ctwm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:ctwm-content-creation-latest

# twm
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:twm-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:twm-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:twm-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:twm-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:twm-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:twm-content-creation-latest

# nixos (Openbox shell + Nix package manager; pairs with the nixos flavor)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:nixos-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:nixos-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:nixos-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:nixos-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:nixos-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:nixos-content-creation-latest

# pearos (macOS-inspired KDE Plasma; pairs with the pearos flavor)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pearos-none-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pearos-minimal-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pearos-gaming-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pearos-development-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pearos-office-latest
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:pearos-content-creation-latest

```

### 2. Single-app images (ultra-minimal, no desktop)

```bash
# Chrome only, no desktop environment
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:browser-latest
# Discord only, no desktop environment
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:discord-latest
# VSCodium only, no desktop environment
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:vscode-latest
# Terminal only, no desktop environment
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:terminal-latest
```

### 3. Distro-flavor images

```bash
# FastVM OS appliance (XFCE4 + development)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:fastvm-os-latest
# Ubuntu Studio 22.04 (KDE + creative tooling)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:ubuntu-studio-latest
# Ubuntu Kylin 22.04 (UKUI)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:ubuntu-kylin-latest
# Ubuntu Budgie 22.04
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:ubuntu-budgie-latest
# Ubuntu Edubuntu 22.04 (GNOME, education)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:ubuntu-edubuntu-latest
# Xubuntu 22.04 (XFCE4)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:xubuntu-latest
# Lubuntu 22.04 (LXQt)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:lubuntu-latest
# Kubuntu 22.04 (KDE Plasma)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:kubuntu-latest
# Ubuntu MATE 22.04
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:ubuntu-mate-latest
# Ubuntu Unity 22.04
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:ubuntu-unity-latest
# Pop!_OS (System76 GNOME)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:pop-os-latest
# Linux Mint (Cinnamon)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:linuxmint-latest
# Kali Linux (XFCE4, security tooling)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:kali-latest
# Parrot Security OS (MATE)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:parrot-latest
# NixOS flavor (Openbox shell + Nix package manager)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:nixos-latest
# pearOS (macOS-inspired KDE Plasma)
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:pearos-latest
```

### 4. Docker Compose deployments

```bash
# Base stack (whatever FASTVM_DE/FASTVM_PRESET are set to in config.env):
docker compose up -d --build

# Publish a specific desktop/preset with no overlay:
FASTVM_DE=KDE FASTVM_PRESET=gaming docker compose up -d --build

# fastvm-os flavor overlay (FastVM OS appliance (XFCE4 + development))
docker compose -f docker-compose.yml -f docker-compose.fastvm-os.yml up -d --build

# ubuntu-studio flavor overlay (Ubuntu Studio 22.04 (KDE + creative tooling))
docker compose -f docker-compose.yml -f docker-compose.ubuntu-studio.yml up -d --build

# ubuntu-kylin flavor overlay (Ubuntu Kylin 22.04 (UKUI))
docker compose -f docker-compose.yml -f docker-compose.ubuntu-kylin.yml up -d --build

# ubuntu-budgie flavor overlay (Ubuntu Budgie 22.04)
docker compose -f docker-compose.yml -f docker-compose.ubuntu-budgie.yml up -d --build

# ubuntu-edubuntu flavor overlay (Ubuntu Edubuntu 22.04 (GNOME, education))
docker compose -f docker-compose.yml -f docker-compose.ubuntu-edubuntu.yml up -d --build

# xubuntu flavor overlay (Xubuntu 22.04 (XFCE4))
docker compose -f docker-compose.yml -f docker-compose.xubuntu.yml up -d --build

# lubuntu flavor overlay (Lubuntu 22.04 (LXQt))
docker compose -f docker-compose.yml -f docker-compose.lubuntu.yml up -d --build

# kubuntu flavor overlay (Kubuntu 22.04 (KDE Plasma))
docker compose -f docker-compose.yml -f docker-compose.kubuntu.yml up -d --build

# ubuntu-mate flavor overlay (Ubuntu MATE 22.04)
docker compose -f docker-compose.yml -f docker-compose.ubuntu-mate.yml up -d --build

# ubuntu-unity flavor overlay (Ubuntu Unity 22.04)
docker compose -f docker-compose.yml -f docker-compose.ubuntu-unity.yml up -d --build

# pop-os flavor overlay (Pop!_OS (System76 GNOME))
docker compose -f docker-compose.yml -f docker-compose.pop-os.yml up -d --build

# linuxmint flavor overlay (Linux Mint (Cinnamon))
docker compose -f docker-compose.yml -f docker-compose.linuxmint.yml up -d --build

# kali flavor overlay (Kali Linux (XFCE4, security tooling))
docker compose -f docker-compose.yml -f docker-compose.kali.yml up -d --build

# parrot flavor overlay (Parrot Security OS (MATE))
docker compose -f docker-compose.yml -f docker-compose.parrot.yml up -d --build

# nixos flavor overlay (NixOS identity + Nix package manager on an Openbox shell)
docker compose -f docker-compose.yml -f docker-compose.nixos.yml up -d --build

# pearos flavor overlay (pearOS macOS-inspired KDE Plasma)
docker compose -f docker-compose.yml -f docker-compose.pearos.yml up -d --build

```

### 5. Build straight from the Dockerfile

```bash
# Build any desktop/preset locally:
docker build -f Dockerfile.optimized \
  --build-arg FASTVM_DE=XFCE4 \
  --build-arg FASTVM_PRESET=development \
  -t fastvm:local .
docker run -d -p 3000:3000 -p 3001:8099 fastvm:local

# Build a distro flavor locally:
docker build -f Dockerfile.optimized \
  --build-arg FASTVM_DE=XFCE4 \
  --build-arg FASTVM_PRESET=development \
  --build-arg FASTVM_OS_FLAVOR=kali \
  -t fastvm:kali .
docker run -d -p 3000:3000 -p 3001:8099 fastvm:kali
```

### 6. Helper install script

The `./fastvm-install.sh` helper wraps the build/run flow and bakes a desktop and (optionally) a distro flavor into a local image.

```bash
# Desktop only (default XFCE4). The helper reads config.env and any
# FASTVM_* environment variable you export:
./fastvm-install.sh
FASTVM_DE=KDE FASTVM_PRESET=gaming ./fastvm-install.sh

# Desktop + distro flavor:
FASTVM_DE=XFCE4 FASTVM_OS_FLAVOR=fastvm-os ./fastvm-install.sh
FASTVM_DE=KDE FASTVM_OS_FLAVOR=ubuntu-studio ./fastvm-install.sh
FASTVM_DE=UKUI FASTVM_OS_FLAVOR=ubuntu-kylin ./fastvm-install.sh
FASTVM_DE=Budgie FASTVM_OS_FLAVOR=ubuntu-budgie ./fastvm-install.sh
FASTVM_DE=GNOME FASTVM_OS_FLAVOR=ubuntu-edubuntu ./fastvm-install.sh
FASTVM_DE=XFCE4 FASTVM_OS_FLAVOR=xubuntu ./fastvm-install.sh
FASTVM_DE=LXQT FASTVM_OS_FLAVOR=lubuntu ./fastvm-install.sh
FASTVM_DE=KDE FASTVM_OS_FLAVOR=kubuntu ./fastvm-install.sh
FASTVM_DE=MATE FASTVM_OS_FLAVOR=ubuntu-mate ./fastvm-install.sh
FASTVM_DE=Unity FASTVM_OS_FLAVOR=ubuntu-unity ./fastvm-install.sh
FASTVM_DE=pop-os FASTVM_OS_FLAVOR=pop-os ./fastvm-install.sh
FASTVM_DE=Cinnamon FASTVM_OS_FLAVOR=linuxmint ./fastvm-install.sh
FASTVM_DE=XFCE4 FASTVM_OS_FLAVOR=kali ./fastvm-install.sh
FASTVM_DE=MATE FASTVM_OS_FLAVOR=parrot ./fastvm-install.sh
FASTVM_DE=nixos FASTVM_OS_FLAVOR=nixos ./fastvm-install.sh
FASTVM_DE=pearos FASTVM_OS_FLAVOR=pearos ./fastvm-install.sh
```

---

## 🧩 Distro-flavor images

Distro-flavor images are **additive**: each layers a distro identity over the
same Ubuntu 22.04 / KasmVNC base and never replaces the desktop, preset, or
single-app images. Deploy one with its `<flavor>-latest` tag (dashboard on
port `3001`):

| Flavor | Desktop | Identity layer |
|:---|:---|:---|
| `fastvm-os` | XFCE4 + development | FastVM OS appliance shell |
| `ubuntu-studio` | KDE Plasma | Ubuntu Studio 22.04 |
| `ubuntu-kylin` | UKUI | Ubuntu Kylin 22.04 |
| `ubuntu-budgie` | Budgie | Ubuntu Budgie 22.04 |
| `ubuntu-edubuntu` | GNOME | Ubuntu Edubuntu 22.04 |
| `xubuntu` | XFCE4 | Xubuntu 22.04 |
| `lubuntu` | LXQt | Lubuntu 22.04 |
| `kubuntu` | KDE Plasma | Kubuntu 22.04 |
| `ubuntu-mate` | MATE | Ubuntu MATE 22.04 |
| `ubuntu-unity` | Unity | Ubuntu Unity 22.04 |
| `pop-os` | GNOME | Pop!_OS (System76 themes) |
| `linuxmint` | Cinnamon | Linux Mint |
| `kali` | XFCE4 | Kali Linux (security tooling) |
| `parrot` | MATE | Parrot Security OS |
| `nixos` | Openbox | NixOS identity + Nix package manager |
| `pearos` | KDE Plasma | pearOS (macOS-inspired) |

```bash
# FastVM OS appliance
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:fastvm-os-latest

# Any other flavor, e.g. pearOS
docker run -d -p 3000:3000 -p 3001:8099 ghcr.io/cloudcompile/fastvm:pearos-latest
```

**Recovery and updates:** the dashboard **System** view writes authenticated
`recovery`/`update` requests to `data/.fastvm/system-action.json`. The dashboard
does not mount the Docker socket and cannot restart or replace its own
container; a trusted host operator consumes requests with
`scripts/fastvm-supervisor.sh`, then runs the approved snapshot or Compose
workflow. The supported FastVM OS artifact is the browser-appliance Docker
image — bootable ISO and cloud-image packaging remain future artifacts until
persistence, hardware, and update tests are complete.

---

## 🛒 **FastVM Marketplace (desktop app)**

Prefer clicking to typing? `desktop-app/` is a **Tauri 2** desktop client that
turns FastVM into a one-click marketplace for streamed Linux desktops.

Browse desktops, distros, and presets, pick one, and hit **Deploy** — the app
builds the `docker run` command, starts the container, and opens the desktop in
your browser. Running instances show up with Open / Dashboard / Logs / Stop /
Remove actions. It runs on Linux, Windows, and macOS.

```bash
cd desktop-app
npm install
npm run dev      # develop
npm run build    # build installers for your OS
```

It needs the Docker CLI installed and running. See
[`desktop-app/README.md`](desktop-app/README.md) for the architecture and
security notes.

---

## ✨ **WHAT YOU GET**

### 🎯 **Core Powers**

| 🏃 SPEED | 🎨 CHOICE | ☁️ CLOUD | 💾 DATA |
|:---:|:---:|:---:|:---:|
| **30-sec startup** | **36 desktops** | **Deploy anywhere** | **Auto-backup** |
| 236 prebuilt images | XFCE4 → Pop!_OS | Codespaces ready | Point-in-time restore |
| Parallel CI/CD | Pick your vibe | Infinite scaling | Persistent storage |
| Layer caching | Lightweight+full | Zero local setup | Snapshot manager |

---

## 🎮 **PRODUCTION-READY IMAGES**

<div align="center">

### **Pick Your Flavor**

### Single-App Variants (Ultra-Minimal)

| Variant | What You Get | Size | Startup |
|:---|:---|:---:|:---:|
| **browser-latest** 🌐 | Just Chrome. Nothing else. | ~900 MB | **15s** |
| **discord-latest** 💬 | Just Discord. Nothing else. | ~850 MB | **15s** |
| **vscode-latest** 💻 | Just VSCodium. Nothing else. | ~1.1 GB | **15s** |
| **terminal-latest** ⌨️ | Just terminal + tmux + vim | ~500 MB | **10s** |

### Desktop + Preset Combinations

| Variant | Speed ⚡ | Size 💾 | Startup ⏱️ | Best For |
|:---|:---:|:---:|:---:|:---|
| **xfce4-minimal** | ⚡⚡⚡⚡⚡ | 1.5 GB | 30s | ⭐ Recommended |
| **lxqt-minimal** | ⚡⚡⚡⚡⚡ | 1.2 GB | 25s | 2-core machines |
| **i3-minimal** | ⚡⚡⚡⚡⚡ | 1.1 GB | 20s | Keyboard users |
| **kde-gaming** | ⚡⚡⚡ | 2.8 GB | 90s | Gaming |
| **xfce4-development** | ⚡⚡⚡⚡ | 2.0 GB | 60s | Coding |
| **gnome-office** | ⚡⚡⚡ | 2.4 GB | 70s | Office work |

### 🚀 **Quick Start**

```bash
# ⚡ Just a browser (fastest possible — 15s startup)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:browser-latest

# 💬 Just Discord
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:discord-latest

# 💻 Just VSCodium
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:vscode-latest

# 🏃 Full XFCE4 minimal desktop
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-minimal-latest

# 🎮 Gaming (KDE + Steam + Wine, CPU-rendered)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-gaming-latest

# 🖥️ Local Docker with GPU (NOT available in Codespaces)
docker run -d -p 3000:3000 --device /dev/dri ghcr.io/cloudcompile/fastvm:kde-gaming-latest
```

</div>

---

## 🎛️ **CHOOSE YOUR DESKTOP**

| Desktop | RAM | Speed | Vibe | Why Pick It? |
|:---|:---:|:---:|:---|:---|
| 🏃 **XFCE4** | 512 MB | ⚡⚡⚡⚡⚡ | Classic GTK | Default for a reason — fast, stable, proven |
| 👑 **KDE Plasma** | 1.5 GB | ⚡⚡⚡ | Modern Qt | Power users who love customization |
| 🍒 **GNOME** | 2 GB | ⚡⚡ | Sleek | Modern macOS-like feel |
| 🎨 **Cinnamon** | 1 GB | ⚡⚡⚡⚡ | Windows-like | Windows users feel at home |
| 🪶 **LXQT** | 256 MB | ⚡⚡⚡⚡⚡ | Minimal | Ultra-light, 2-core friendly |
| ⌨️ **i3** | 128 MB | ⚡⚡⚡⚡⚡ | Tiling | Keyboard-driven power users |
| 🎯 **Budgie** | 512 MB | ⚡⚡⚡⚡ | Clean | Minimalist aesthetic |
| 🟢 **MATE** | 512 MB | ⚡⚡⚡⚡ | Classic GNOME 2 | Familiar traditional layout, actively maintained |
| 🪶 **LXDE** | 192 MB | ⚡⚡⚡⚡⚡ | Ultra-light GTK2 | Lowest-footprint full desktop for tiny hosts |
| 🟦 **Fluxbox** | 128 MB | ⚡⚡⚡⚡⚡ | Minimal WM | No desktop shell — fastest possible session |
| 🟣 **Unity** | 1 GB | ⚡⚡⚡ | Ubuntu classic | The familiar Ubuntu 16.04-era shell |
| 🎬 **Ubuntu Studio** | 1.5 GB | ⚡⚡⚡ | KDE multimedia | Ubuntu Studio 22.04 flavor with distro identity |
| ⚡ **Enlightenment** | 384 MB | ⚡⚡⚡⚡ | Eye candy | Flashy compositing effects with a light footprint |
| ❄️ **IceWM** | 128 MB | ⚡⚡⚡⚡⚡ | Very light | Taskbar + menu, near-zero RAM, great on tiny hosts |
| 🔲 **awesome** | 160 MB | ⚡⚡⚡⚡⚡ | Tiling | Lua-scriptable tiling WM, keyboard-driven workflows |
| 🇨🇳 **UKUI** | 1 GB | ⚡⚡⚡⚡ | Kylin | Ubuntu Kylin's desktop, pairs with the ubuntu-kylin flavor |
| 🧩 **bspwm** | 128 MB | ⚡⚡⚡⚡⚡ | Tiling (BSP) | Binary space partitioning with sxhkd hotkeys, ultra-light |
| 🖥️ **GNOME Flashback** | 512 MB | ⚡⚡⚡⚡ | Classic GNOME 2 | The GNOME 2 panel layout on a maintained stack |
| 🪟 **Window Maker** | 128 MB | ⚡⚡⚡⚡⚡ | NeXTSTEP-style | Iconic dock and app icons, extremely light |
| 🌿 **herbstluftwm** | 128 MB | ⚡⚡⚡⚡⚡ | Tiling (manual) | Manual tiling WM driven by hotkeys, dmenu launcher, ultra-light |
| 🧰 **JWM** | 128 MB | ⚡⚡⚡⚡⚡ | Stacking WM | Joe's Window Manager — XML-configured taskbar/pager, ultra-light |
| 🏛️ **FVWM** | 160 MB | ⚡⚡⚡⚡ | Classic WM | F? Virtual Window Manager — scriptable virtual-desktop WM, fixed since 1993 |
| ⌨️ **XMonad** | 128 MB | ⚡⚡⚡⚡⚡ | Tiling (Haskell) | xmonad + xmobar, compiled-in default config, keyboard-driven, ultra-light |
| 🍬 **Sugar** | 384 MB | ⚡⚡⚡⚡ | Activity shell | Sugar Learning Platform (OLPC) education desktop for kids |
| 🪟 **dwm** | 96 MB | ⚡⚡⚡⚡⚡ | Tiling (suckless) | Dynamic window manager — st + dmenu, tiny C codebase, ultra-light |
| ⌨️ **Ratpoison** | 96 MB | ⚡⚡⚡⚡⚡ | Tiling (keyboard) | Screen-style keyboard WM, no mouse required, ultra-light |
| ⬛ **Blackbox** | 96 MB | ⚡⚡⚡⚡⚡ | Stacking WM | Minimal WM with a right-click root menu, ultra-light |
| 🧊 **PekWM** | 96 MB | ⚡⚡⚡⚡⚡ | Stacking WM | Very lightweight stacking WM with a right-click root menu, made for speed |
| ⌨️ **spectrwm** | 96 MB | ⚡⚡⚡⚡⚡ | Dynamic tiling | Xmonad/i3-inspired dynamic tiling WM, keyboard driven, extremely light |
| 🐟 **Sawfish** | 128 MB | ⚡⚡⚡⚡⚡ | Lisp-scriptable WM | Reparenting WM scripted in Lisp, highly configurable, light |
| 🪟 **Openbox** | 128 MB | ⚡⚡⚡⚡⚡ | Stacking WM | Configurable stacking WM with tint2 panel + rofi launcher, very light |
| 🔷 **AfterStep** | 160 MB | ⚡⚡⚡⚡ | NeXTSTEP-style | NeXTSTEP-inspired WM with Wharf dock and Pager, light |
| 🏛️ **CTWM** | 128 MB | ⚡⚡⚡⚡⚡ | Classic WM | twm with virtual desktops and a window menu, very light |
| ⬛ **TWM** | 96 MB | ⚡⚡⚡⚡⚡ | Minimal WM | The original X11 tab window manager, absolute minimum |
| ❄️ **NixOS** | 256 MB | ⚡⚡⚡⚡ | Openbox + Nix | NixOS identity layer with the Nix package manager on an Openbox shell |
| 🟠 **Pop!_OS** | 2 GB | ⚡⚡ | GNOME (System76) | Pop!_OS 22.04 GNOME Shell + Pop GTK/icon themes, pairs with the pop-os flavor |
| 🍐 **pearOS** | 1.5 GB | ⚡⚡⚡ | macOS-like KDE | macOS-inspired KDE Plasma desktop + Papirus icons, pairs with the pearos flavor |

---

## 🎮 **GAMING**

✅ **Wine support** (x86-64 + i386)
✅ **Steam integration** with Proton
✅ **Flatpak support** for launcher-based gaming
✅ **Optional gaming extras** — Heroic (Epic), Modrinth, TLauncher, Minecraft
✅ **CPU-rendered** — Codespaces is CPU-only (no GPU)
✅ **Local Docker:** optional GPU via `--device /dev/dri`
✅ **Games run** — just no hardware acceleration in Codespaces

> Windows is not a supported FastVM target. It is intentionally omitted because Windows desktop sessions are too slow and resource-heavy for the browser-streaming model used here.

---

## 📊 **ADVANCED FEATURES**

### ⚙️ Configuration
- **One `config.env` file** controls everything
- **6 presets** — gaming, development, office, content-creation, minimal, free-vps
- **Per-app toggles** — install exactly what you need
- **Desktop choice** — switch with one variable

### 📈 Monitoring
- **Live dashboard** on port 3001
- **Real-time graphs** for CPU, RAM, disk
- **Performance metrics** updated every 5 seconds
- **System health checks** automated

### 🎬 Media & Recording
- **Screen recording** with ffmpeg
- **Audio forwarding** via PulseAudio for every desktop and single-app image
- **Audio input and output** use the PulseAudio/browser bridge provided by the KasmVNC base image; run `/fastvm-scripts/audio-self-test.sh` inside a running container to verify the active sink and source
- **Bidirectional clipboard** sync
- **Mic input** support

### 💾 Data Management
- **Automatic snapshots** with scheduler
- **One-command restore** to any point-in-time
- **Scheduled backups** in background
- **Data survives** container restarts

---

## 🔧 **DEVELOPER TOOLS**

### 🚀 Quick Start
```bash
# Option 1: Docker (30 seconds)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-none-latest
open http://localhost:3000

# Option 2: Codespaces (2 minutes)
# Fork → Codespaces → ./fastvm-install.sh → Click port 3000
```

### ⚙️ Configuration
```bash
# Edit config.env:
FASTVM_DE=XFCE4                    # Desktop choice
FASTVM_PRESET=minimal              # App bundle preset
FASTVM_APP_CHROME=true             # Install Chrome
FASTVM_APP_WINE=false              # Skip Wine
FASTVM_PROG_AUDIO=true             # Include audio system
```

### 📦 Container Management
```bash
docker-compose up -d               # Start
docker-compose logs -f             # Watch logs
docker-compose stop                # Stop safely
docker-compose restart             # Restart

# Dashboard
open http://localhost:3001
cat data/dashboard.token           # Get auth token
```

---

## 🎯 **PRESETS** — Auto-Configure Everything

| Preset | What's Included | Startup | Best For |
|:---|:---|:---:|:---|
| **minimal** | Terminal + Browser | 30s | Speed, quick tasks |
| **gaming** | Steam, Wine, Lutris | 90s | Gaming, Proton |
| **development** | VSCodium, Git, Node | 120s | Coding, dev work |
| **office** | LibreOffice suite | 90s | Documents, spreadsheets |
| **content-creation** | GIMP, Blender, VLC | 150s | Media, design |
| **hidencloud-free-vps** | Ultra-light non-root profile, no heavy extras | 25s | Free Pterodactyl VPS + Cloudflare |

---

## ☁️ **PTERODACTYL + CLOUDFLARE (FREE VPS PROFILE)**

Deploy FastVM on **HiddenCloud's free Pterodactyl VPS** (2 vCPU / 3 GB RAM / 15 GB storage) with automatic resource management:

### 📋 **Via app.py (Pterodactyl Panel Deployment)**

Pterodactyl panels typically restrict deployments to `app.py` + `requirements.txt`. Use the included Python launcher:

```bash
# 1. Upload repo files to your Pterodactyl server
# 2. In the panel, upload or paste app.py as your startup command
# 3. The launcher automatically handles:
#    - Docker/Podman detection and installation
#    - Non-root user setup (required for free VPS)
#    - Resource constraints (2 CPU, 3 GB RAM, 1 GB shared memory)
#    - Preset configuration loading

# Start FastVM
python3 app.py start

# Check status
python3 app.py status

# View logs
python3 app.py logs

# Stop FastVM
python3 app.py stop
```

For Pterodactyl, upload the complete FastVM project, including `app.py`,
`config.env`, `docker-compose.yml`, and the Docker build context. If the panel
stores configuration elsewhere, use
`FASTVM_CONFIG_FILE=/absolute/path/config.env python3 app.py`.

### ⚙️ **Configuration**

```bash
# Ensure config.env has these settings:
FASTVM_PRESET=hidencloud-free-vps      # Pre-tuned for 2 vCPU / 3 GB RAM
FASTVM_PORT=3000                       # Web desktop port
FASTVM_DASHBOARD_HOST_PORT=3001        # Dashboard port
FASTVM_CPU_LIMIT=2                     # Respect VPS limits
FASTVM_MEMORY_LIMIT=3g                 # Max 3 GB
FASTVM_SHM_SIZE=1gb                    # Shared memory
FASTVM_DE=LXQT                         # Lightweight desktop
```

### 🌐 **Expose via Cloudflare Tunnel**

```bash
# Install Cloudflare Tunnel agent on your VPS
# Then create a tunnel to expose the ports:
cloudflare-tunnel run \
  --url http://localhost:3000 \
  --url http://localhost:3001 \
  my-fastvm-tunnel

# Access via your Cloudflare domain
# https://fastvm.yourdomain.com → localhost:3000
# https://dashboard.yourdomain.com → localhost:3001
```

### ✅ **What the Preset Includes**

- **LXQT Desktop** — Minimal, fast (fits in 3 GB)
- **Firefox + Terminal** — Essential tools only
- **No extras** — Wine, Chrome, Steam, recording, audio disabled
- **Auto-scaling disabled** — To avoid thrashing on 2 vCPU
- **Backups disabled** — To conserve 15 GB storage

### 📊 **Typical Performance**

| Metric | Value |
|:---|---:|
| **Boot time** | 25-30 seconds |
| **RAM usage** | 2.2-2.8 GB |
| **CPU load** | 30-50% (idle) |
| **Storage used** | ~9-12 GB |
| **Simultaneous users** | 1-2 |

---

## 🖥️ **MACHINE SIZE GUIDE**

| Codespace | RAM | Cores | Best Desktop | Experience |
|:---|:---:|:---:|:---|:---|
| **2-core** | 8 GB | 2 | XFCE4, LXQT | ✅ Works fine (auto-tuned) |
| **4-core** ⭐ | 16 GB | 4 | Any | ✅✅ **Recommended** |
| **8-core** | 32 GB | 8 | Any | ✅✅✅ Butter smooth |

FastVM measures the host at startup and applies a **performance profile**
automatically (`docs/performance.md`): on a 2-core / 8 GB / no-GPU box it clamps
the software renderer to the vCPU count, frees a core for the recorder, and turns
off desktop compositing. Set `FASTVM_PERF_PROFILE=performance` in `config.env` to
disable the automatic tuning.

---

## 🛠️ **TROUBLESHOOTING**

### ❓ Port 3000 not loading?
```bash
# 1. Wait 60 seconds (building takes time)
# 2. Refresh the page
# 3. Check if running:
docker ps
docker-compose logs
```

### 🐢 Desktop feels slow?
```bash
# In config.env:
FASTVM_DE=XFCE4                    # Use lightweight desktop
FASTVM_PRESET=minimal              # Strip to essentials
FASTVM_SHM_SIZE=4gb                # Add shared memory
```

### ⚙️ Config changes not taking effect?
```bash
# Config only applies on fresh start:
docker-compose down
./fastvm-install.sh
```

### 💥 Build failed?
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## 📁 **ARCHITECTURE**

```
Your Browser (Port 3000)
    ↓ [KasmVNC Streaming]
Linux Desktop (Ubuntu 22.04)
    ↓ [Node.js API]
Management Dashboard (Port 3001)
    ↓ [Docker Container]
Persistent Data (/config)
```

### **What's Included**
- 🐳 **Multi-stage Dockerfile** — optimized layers, ~2GB compressed
- 🎨 **Desktop Environment** — 36 choices, pre-configured
- 📦 **22 App Installers** — Wine, Chrome, Steam, VSCodium, etc.
- 📊 **Node.js Dashboard** — monitoring, recording, backups
- 🔧 **Runtime Scripts** — audio, clipboard, recording, autoscaling
- 📁 **Data Persistence** — survives restarts, automatic backups

---

## 🌟 **FEATURED CAPABILITIES**

### 🎮 Gaming
- Steam + Proton ready
- Wine support (32-bit + 64-bit)
- GPU access
- Full performance

### 💻 Development
- VSCodium included
- Git, Node.js, Docker
- Terminal access
- SSH possible

### 🎬 Content Creation
- GIMP pre-installed option
- Audio forwarding
- Screen recording
- ffmpeg codecs

### 📊 Production Ready
- Parallel CI/CD builds
- Layer caching
- Health checks
- Auto-scaling
- Backup management

---

## 🤝 **CONTRIBUTING**

**Code standards:**
- `set -euo pipefail` in all scripts
- Log with helpers from `lib-common.sh`
- One `apt-get update` per layer
- No unnecessary delays

**To contribute:**
1. Fork → branch → code
2. Test on multiple desktops
3. Keep PRs focused
4. Clear commit messages

---

<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=150&section=footer&animation=tilt"/>
  <img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=6366f1&height=150&section=footer&animation=tilt"/>
</picture>

### 💝 **Love FastVM?**

**[⭐ Star the repo](https://github.com/CloudCompile/fastvm/stargazers)** · **[🐛 Report Bug](https://github.com/CloudCompile/fastvm/issues/new)** · **[💡 Request Feature](https://github.com/CloudCompile/fastvm/issues/new)** · **[💬 Discuss](https://github.com/CloudCompile/fastvm/discussions)**

<br/>

**Built with ❤️ by CloudCompile**

Powered by [LinuxServer.io](https://linuxserver.io) · Streamed via [KasmVNC](https://kasmweb.com) · Containerized with [Docker](https://docker.com)

**MIT License** — Free to use, modify, commercialize

---

> **Linux Desktop. Streamed. Instant.**
> 
> Deploy anywhere. Scale infinitely. **Zero setup.**

</div>
