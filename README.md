# FastVM

**FastVM gives you a full Linux desktop — right inside your web browser.** It runs entirely inside a Docker container, so nothing gets installed on your computer. Just open a tab and you have a working desktop.

> **New to Docker or Linux?** Don't worry — this guide walks you through every step.

---

## 📖 Table of Contents

1. [What You Need](#-what-you-need)
2. [Quick Start (5 steps)](#-quick-start-5-steps)
3. [What You'll See After Installing](#-what-youll-see-after-installing)
4. [Customizing FastVM](#️-customizing-fastvm)
5. [Managing FastVM](#-managing-fastvm)
6. [Troubleshooting](#-troubleshooting)
7. [Advanced Usage](#-advanced-usage)
8. [Contributing](#-contributing)

---

## ✅ What You Need

Before you start, make sure you have these installed:

| Tool | What it does | Install guide |
|------|-------------|---------------|
| **Docker** | Runs FastVM in an isolated container | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| **Docker Compose** | Manages the container easily | Included with Docker Desktop; for Linux: [docs.docker.com/compose/install](https://docs.docker.com/compose/install/) |
| **Git** | Downloads this repository | [git-scm.com/downloads](https://git-scm.com/downloads) |

> **Windows users:** Install [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/) and use it inside WSL2 (Windows Subsystem for Linux). [Here's a guide.](https://docs.docker.com/desktop/wsl/)

Once Docker is installed, make sure it's **running** before you continue (you should see the Docker icon in your system tray, or `docker info` should work without errors).

---

## 🚀 Quick Start (5 steps)

### Step 1 — Download FastVM

Open a terminal and run:

```bash
git clone https://github.com/CloudCompile/fastvm.git
cd fastvm
```

This downloads all the files into a folder called `fastvm` and moves you into it.

---

### Step 2 — (Optional) Customize before installing

Open the file `config.env` in any text editor. The defaults work fine for most people, but here are the most common things to change:

```bash
# Which port to open in your browser (default is 3000)
FASTVM_PORT=3000

# Your timezone — makes the clock correct inside the VM
# Examples: America/New_York, Europe/London, Asia/Tokyo
FASTVM_TZ=Etc/UTC

# Desktop environment (XFCE4 is the best starting point)
FASTVM_DE=XFCE4
```

Save and close the file when you're done. You can always change these later and restart.

---

### Step 3 — Run the installer

```bash
chmod +x fastvm-install.sh
./fastvm-install.sh
```

The installer will:
1. Check that Docker and Git are ready
2. Build the Docker image (this takes **5–15 minutes** the first time — normal!)
3. Start the container
4. Tell you the URL to open

> ☕ Grab a coffee — the first build downloads a full Linux system image.

---

### Step 4 — Open FastVM in your browser

When the installer finishes, you'll see something like:

```
  - Local URL:    http://localhost:3000
```

Open that URL in Chrome, Firefox, or any modern browser. You should see a Linux desktop load right in the tab.

---

### Step 5 — You're done! 🎉

FastVM is now running. You can use it like a normal computer — open apps, browse the web inside the VM, run programs, etc.

---

## 🖥️ What You'll See After Installing

After opening `http://localhost:3000` you'll see an **XFCE4 desktop** (or whichever desktop you chose). It works just like a regular Linux computer:

- **Right-click** the desktop to open a menu
- **The taskbar** at the bottom has common apps
- **File manager, terminal, and browser** are available by default

Your files are saved in the `data/` folder on your computer, so they persist between restarts.

---

## ⚙️ Customizing FastVM

All settings live in `config.env`. Open it in any text editor, make your changes, then [restart FastVM](#-managing-fastvm) for them to take effect.

### Choosing a desktop environment

| Setting | Best for |
|---------|----------|
| `FASTVM_DE=XFCE4` | **Recommended for beginners** — fast and easy to use |
| `FASTVM_DE=KDE` | Full-featured, looks great, needs more RAM |
| `FASTVM_DE=GNOME` | Modern look, similar to macOS, needs the most RAM |
| `FASTVM_DE=Cinnamon` | Feels like Windows, medium resource use |
| `FASTVM_DE=LXQT` | Very lightweight, good for low-end machines |
| `FASTVM_DE=I3` | Keyboard-driven tiling layout, for advanced users |

### Choosing which apps to pre-install

Edit these lines in `config.env` — set to `true` to install, `false` to skip:

```bash
FASTVM_APP_WINE=true        # Run Windows .exe files inside Linux
FASTVM_APP_CHROME=true      # Google Chrome browser
FASTVM_APP_DISCORD=false    # Discord chat app
FASTVM_APP_STEAM=false      # Steam game launcher
FASTVM_APP_MINECRAFT=false  # Minecraft launcher
FASTVM_APP_VLC=false        # VLC media player
FASTVM_APP_LIBREOFFICE=false # Office suite (Word/Excel alternative)

# Programming tools
FASTVM_PROG_VSCODIUM=false  # VS Code (open-source version)
FASTVM_PROG_JAVA17=false    # Java 17
```

### Changing the port

If port 3000 is already in use on your machine:

```bash
FASTVM_PORT=8080
```

Then access FastVM at `http://localhost:8080` instead.

### Setting resource limits

By default FastVM can use all available CPU and RAM. To limit it:

```bash
FASTVM_CPU_LIMIT=2    # Max 2 CPU cores
FASTVM_MEMORY_LIMIT=4g  # Max 4 GB RAM
FASTVM_SHM_SIZE=2gb   # Shared memory (increase if apps crash)
```

---

## 🐳 Managing FastVM

After the first install, use these commands to control FastVM:

```bash
# Start FastVM (after stopping it)
docker-compose up -d

# Stop FastVM (saves your data)
docker-compose stop

# Restart FastVM
docker-compose restart

# View live logs (useful if something is wrong)
docker-compose logs -f

# Remove FastVM completely (your data/ folder stays safe)
docker-compose down
```

> **Tip:** Your files are always safe in the `data/` folder even after `docker-compose down`.

### Updating FastVM

To get the latest version:

```bash
git pull
docker-compose build
docker-compose up -d
```

---

## 🛠️ Troubleshooting

### "I can't open localhost:3000 — the page won't load"

The container might still be starting up. Wait about 60 seconds after running the installer, then try again.

Check if the container is actually running:

```bash
docker ps
```

You should see a container named `FastVM` in the list. If you don't, check the logs:

```bash
docker-compose logs
```

### "Port 3000 is already in use"

Another program is using that port. Change the port in `config.env`:

```bash
FASTVM_PORT=3001
```

Then restart: `docker-compose up -d`

### "The desktop is really slow"

Try these fixes (edit `config.env` then restart):

1. **Enable KVM** for much better performance (requires a Linux host with `/dev/kvm`):
   ```bash
   FASTVM_ENABLE_KVM=true
   ```
2. **Give it more shared memory** (helps if apps are crashing or freezing):
   ```bash
   FASTVM_SHM_SIZE=4gb
   ```
3. **Give it more RAM:**
   ```bash
   FASTVM_MEMORY_LIMIT=4g
   ```
4. **Switch to a lighter desktop:**
   ```bash
   FASTVM_DE=XFCE4
   ```

### "Permission denied" errors

```bash
sudo chown -R 1000:1000 ./data
```

### "The build failed"

Try a clean rebuild:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### "I don't see my changes after editing config.env"

You need to restart the container:

```bash
docker-compose down
./fastvm-install.sh
```

---

## 📁 File Structure

Here's what each file does, in case you're curious:

```
fastvm/
├── config.env              ← Edit this to customize FastVM
├── docker-compose.yml      ← Defines how Docker runs the container
├── Dockerfile.optimized    ← Instructions for building the image
├── fastvm-install.sh       ← The installer you ran in Step 3
├── fastvm-setup.sh         ← Sets up the desktop environment inside the container
├── installapps-parallel.sh ← Installs your selected apps in parallel
├── README.md               ← This file
├── data/                   ← Your persistent files (created on first run)
└── logs/                   ← Log files (created on first run)
```

---

## 🔧 Advanced Usage

### Enable KVM acceleration

KVM makes the VM significantly faster, but requires a Linux host with virtualization enabled in BIOS.

Check if KVM is available:
```bash
ls /dev/kvm
```

If that file exists, set `FASTVM_ENABLE_KVM=true` in `config.env` and restart.

### Custom build arguments

```bash
export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
export VERSION=1.0.0
docker-compose build
```

### Checking container health

```bash
# Quick health status
docker inspect --format='{{.State.Health.Status}}' FastVM

# Live resource usage
docker stats FastVM
```

---

## 🤝 Contributing

Contributions are welcome! When contributing code, please follow these conventions already used in the project:

- Scripts use `set -euo pipefail` for strict error handling
- No unnecessary `sleep` delays
- Use `jq -e` instead of `jq | grep`
- Consolidate APT operations into a single `apt-get update`
- Add logging with the `log_info` / `log_success` / `log_error` helpers

---

## 📜 License

This project is based on the original BlobeVM and maintains the same license terms.

## 🙏 Acknowledgments

- Original BlobeVM project
- LinuxServer.io for base images
- Docker and Docker Compose teams
