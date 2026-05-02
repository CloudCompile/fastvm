# FastVM

**FastVM gives you a full Linux desktop inside a GitHub Codespace — accessible from any browser, no local installs required.** Fork this repo, open it in a Codespace, run one command, and you have a working Linux desktop in a new browser tab.

---

## 📖 Table of Contents

1. [How It Works](#-how-it-works)
2. [Quick Start](#-quick-start)
3. [Using Prebuilt Images](#-using-prebuilt-images-fastest)
4. [Accessing Your Desktop](#-accessing-your-desktop)
5. [Customizing FastVM](#️-customizing-fastvm)
6. [Managing FastVM](#-managing-fastvm)
7. [Troubleshooting](#-troubleshooting)
8. [File Structure](#-file-structure)
9. [Contributing](#-contributing)

---

## 💡 How It Works

FastVM runs a full Linux desktop environment inside a Docker container. The desktop is streamed to your browser via a built-in web interface — no VNC client needed. Because it runs inside a GitHub Codespace, everything happens in the cloud:

- **No local installs** — Docker, Git, and everything else are already in the Codespace
- **Access from anywhere** — open your Codespace from any device with a browser
- **Persistent storage** — your files survive Codespace restarts via the `data/` folder
- **Auto-restart** — the container restarts automatically when your Codespace resumes

---

## 🚀 Quick Start

### Step 1 — Fork this repository

Click **Fork** at the top of this page to create your own copy of FastVM. Your settings and data will live in your fork.

---

### Step 2 — Open in a Codespace

On your forked repo, click **Code → Codespaces → Create codespace on main**.

> **For better performance**, choose a machine type with at least **4 cores and 8 GB RAM** when creating the Codespace. XFCE4 runs acceptably on 2-core machines; KDE/GNOME need more headroom.

Wait for the Codespace to finish loading — you'll see a VS Code editor in your browser.

---

### Step 3 — (Optional) Customize before installing

Open `config.env` in the editor. The defaults work fine, but common things to change:

```bash
# Your timezone — makes the clock correct inside the desktop
# Examples: America/New_York, Europe/London, Asia/Tokyo
FASTVM_TZ=Etc/UTC

# Desktop environment (XFCE4 is the best starting point)
FASTVM_DE=XFCE4
```

Save the file when done. You can always change these later and restart.

---

### Step 4 — Run the installer

In the Codespace terminal (`` Ctrl+` `` to open it), run:

```bash
chmod +x fastvm-install.sh
./fastvm-install.sh
```

The installer will:
1. Confirm Docker and Git are available
2. Build the Docker image (takes **5–15 minutes** the first time — normal!)
3. Start the container
4. Print the access URL

> ☕ Grab a coffee — the first build downloads a full Linux image.

---

### Step 5 — Open FastVM in your browser

When the installer finishes you'll see:

```
  - Local URL:    http://localhost:3000
```

GitHub will show a pop-up offering to open the forwarded port — click **Open in Browser**. You can also go to the **Ports** tab in VS Code (`Ctrl+Shift+P` → "Ports: Focus on Ports View"), find port 3000, and click the globe icon.

You should see a Linux desktop load in the new tab. 🎉

---

## ⚡ Using Prebuilt Images (Fastest)

Don't want to wait 5–15 minutes for the image to build? Use prebuilt images instead — **instant startup in 30-60 seconds**:

```bash
# Fastest: XFCE4 + Minimal (30 seconds)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest

# Lightweight: LXQT + Minimal (40 seconds)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:lxqt-fast-latest

# Full-featured: KDE Desktop (60 seconds)
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:kde-latest
```

### Available Prebuilt Variants

| Desktop | Standard | Fast ⚡ |
|---------|----------|--------|
| **XFCE4** (lightweight) | `xfce4-latest` | `xfce4-fast-latest` |
| **KDE** (full-featured) | `kde-latest` | `kde-fast-latest` |
| **GNOME** (modern) | `gnome-latest` | `gnome-fast-latest` |
| **Cinnamon** | `cinnamon-latest` | `cinnamon-fast-latest` |
| **LXQT** (ultra-light) | `lxqt-latest` | `lxqt-fast-latest` |
| **i3** (keyboard-driven) | `i3-latest` | `i3-fast-latest` |
| **Budgie** | `budgie-latest` | `budgie-fast-latest` |

### What's the Difference?

**Standard images** include:
- Full preset (Wine, Chrome, and other apps)
- Audio, screen recording, backups enabled
- Everything optimized for features

**Fast images** (⚡) optimize for speed:
- Minimal preset (terminal + browser only)
- Audio, recording, and backups disabled
- ~30% smaller, ~20% faster startup

### Build Your Own

If you need a custom combination or latest changes:

```bash
# Still use the installer for total control
./fastvm-install.sh
```

---

## 🖥️ Accessing Your Desktop

### Finding the URL after the Codespace restarts

FastVM restarts automatically when your Codespace resumes. To find the desktop URL again:

1. Open the **Ports** tab in VS Code
2. Find port **3000**
3. Click the globe 🌐 icon to open it

### Making the port public

By default the forwarded port is private (only you can access it). To share it:

1. Open the **Ports** tab
2. Right-click port 3000 → **Port Visibility → Public**

> ⚠️ Anyone with the URL can access the desktop when set to Public. Only share it if you intend to.

### What you'll see

After opening the URL you'll see an **XFCE4 desktop** (or whichever desktop you chose):

- **Right-click** the desktop to open the application menu
- **The taskbar** at the bottom has common apps
- **File manager, terminal, and browser** are available by default

---

## ⚙️ Customizing FastVM

All settings live in `config.env`. Edit the file, then [restart FastVM](#-managing-fastvm) for changes to take effect.

### Choosing a desktop environment

| Setting | Best for |
|---------|----------|
| `FASTVM_DE=XFCE4` | **Recommended** — fast and easy to use |
| `FASTVM_DE=KDE` | Full-featured, looks great, needs more RAM |
| `FASTVM_DE=GNOME` | Modern look, similar to macOS, needs the most RAM |
| `FASTVM_DE=Cinnamon` | Feels like Windows, medium resource use |
| `FASTVM_DE=LXQT` | Very lightweight, best for 2-core Codespaces |
| `FASTVM_DE=I3` | Keyboard-driven tiling layout, for advanced users |

### Choosing which apps to pre-install

Set to `true` to install, `false` to skip:

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

### Codespace machine size recommendations

| Codespace machine | Recommended desktop | Notes |
|-------------------|--------------------|----|
| 2-core / 8 GB | XFCE4 or LXQT | Functional; avoid Chrome inside the VM |
| 4-core / 16 GB | XFCE4, KDE, or Cinnamon | Good everyday experience |
| 8-core / 32 GB | Any | Smooth even with heavy apps |

---

## 🐳 Managing FastVM

After the first install, use these commands in the Codespace terminal:

```bash
# Start FastVM (after stopping it)
docker-compose up -d

# Stop FastVM
docker-compose stop

# Restart FastVM
docker-compose restart

# View live logs (useful for troubleshooting)
docker-compose logs -f

# Remove the container (your data/ folder stays safe)
docker-compose down
```

> **Tip:** Your files are always safe in the `data/` folder, even after `docker-compose down`.

### Updating FastVM

```bash
git pull
docker-compose build
docker-compose up -d
```

---

## 🛠️ Troubleshooting

### "The port isn't showing up / the page won't load"

The container may still be starting. Wait about 60 seconds after running the installer, then refresh. Check whether it's running:

```bash
docker ps
```

You should see a container named `FastVM`. If not, check the logs:

```bash
docker-compose logs
```

### "The desktop is slow"

Codespace performance depends on machine type. Try these fixes:

1. **Upgrade your Codespace machine** — go to the Codespace settings and switch to a 4-core or 8-core machine.
2. **Switch to a lighter desktop** in `config.env`:
   ```bash
   FASTVM_DE=XFCE4
   ```
3. **Give it more shared memory** (helps if apps crash or freeze):
   ```bash
   FASTVM_SHM_SIZE=4gb
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

```
fastvm/
├── config.env              ← Edit this to customize FastVM
├── docker-compose.yml      ← Defines how Docker runs the container
├── Dockerfile.optimized    ← Instructions for building the image
├── fastvm-install.sh       ← The installer script
├── fastvm-setup.sh         ← Sets up the desktop environment inside the container
├── installapps-parallel.sh ← Installs your selected apps in parallel
├── README.md               ← This file
├── data/                   ← Your persistent files (created on first run)
└── logs/                   ← Log files (created on first run)
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
