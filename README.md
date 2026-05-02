<style>
  :root {
    --primary: #6366f1;
    --primary-dark: #4f46e5;
    --success: #10b981;
    --warning: #f59e0b;
    --danger: #ef4444;
    --dark: #1f2937;
    --light: #f9fafb;
  }
  
  .fastvm-hero {
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
    padding: 60px 20px;
    border-radius: 12px;
    color: white;
    text-align: center;
    margin-bottom: 40px;
  }
  
  .fastvm-title {
    font-size: 3.5em;
    font-weight: 900;
    margin: 0;
    text-shadow: 0 2px 10px rgba(0,0,0,0.2);
    letter-spacing: -1px;
  }
  
  .fastvm-tagline {
    font-size: 1.5em;
    margin: 15px 0 0 0;
    opacity: 0.95;
    font-weight: 300;
  }
  
  .badge-group {
    display: flex;
    gap: 10px;
    justify-content: center;
    flex-wrap: wrap;
    margin: 25px 0 0 0;
  }
  
  .custom-badge {
    display: inline-block;
    padding: 8px 16px;
    border-radius: 50px;
    font-size: 0.85em;
    font-weight: 600;
    text-decoration: none;
    transition: all 0.3s ease;
    border: 2px solid rgba(255,255,255,0.3);
    color: white;
    backdrop-filter: blur(10px);
  }
  
  .custom-badge:hover {
    border-color: rgba(255,255,255,0.8);
    transform: translateY(-2px);
    box-shadow: 0 8px 20px rgba(0,0,0,0.2);
  }
  
  .feature-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin: 40px 0;
  }
  
  .feature-card {
    background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%);
    padding: 25px;
    border-radius: 8px;
    border-left: 4px solid #6366f1;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  }
  
  .feature-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 20px rgba(99,102,241,0.15);
    border-left-color: #8b5cf6;
  }
  
  .feature-icon {
    font-size: 2.5em;
    margin-bottom: 10px;
  }
  
  .feature-card h3 {
    margin: 10px 0;
    color: #1f2937;
    font-size: 1.2em;
  }
  
  .feature-card p {
    margin: 0;
    color: #6b7280;
    font-size: 0.95em;
    line-height: 1.5;
  }
  
  .cmd-box {
    background: #1f2937;
    color: #10b981;
    padding: 16px;
    border-radius: 8px;
    font-family: 'Courier New', monospace;
    font-size: 0.9em;
    overflow-x: auto;
    border: 1px solid #374151;
    margin: 15px 0;
  }
  
  .cmd-copy {
    float: right;
    cursor: pointer;
    opacity: 0.6;
    transition: opacity 0.2s;
  }
  
  .cmd-copy:hover {
    opacity: 1;
  }
  
  .variant-badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.8em;
    font-weight: 600;
    margin: 2px;
  }
  
  .variant-fast {
    background: #dbeafe;
    color: #0c4a6e;
  }
  
  .variant-standard {
    background: #fef3c7;
    color: #78350f;
  }
  
  .section-divider {
    height: 1px;
    background: linear-gradient(90deg, transparent, #e5e7eb, transparent);
    margin: 50px 0;
  }
  
  .cta-button {
    display: inline-block;
    padding: 12px 30px;
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
    color: white;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 600;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(99,102,241,0.3);
  }
  
  .cta-button:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(99,102,241,0.4);
  }
</style>

<div class="fastvm-hero">
  <h1 class="fastvm-title">✨ FastVM</h1>
  <p class="fastvm-tagline">Linux Desktop. In a Tab.</p>
  <div class="badge-group">
    <a href="https://github.com/CloudCompile/fastvm/actions/workflows/build-images.yml" class="custom-badge">
      <span>✓ Build Passing</span>
    </a>
    <a href="LICENSE" class="custom-badge">
      <span>📜 MIT License</span>
    </a>
    <a href="https://github.com/CloudCompile/fastvm/pkgs/container/fastvm" class="custom-badge">
      <span>🐳 14 Images</span>
    </a>
    <a href="https://github.com/CloudCompile/fastvm/stargazers" class="custom-badge">
      <span>⭐ Star Us</span>
    </a>
  </div>
</div>

Transform your browser into a full Linux desktop environment. **No installation. No configuration.** Just fork, click, and code.

---

## 🎯 Why FastVM?

<div class="feature-grid">
  <div class="feature-card">
    <div class="feature-icon">⚡</div>
    <h3>Lightning Fast</h3>
    <p>Deploy in 30-60 seconds with prebuilt images. Full desktop ready to use instantly.</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">☁️</div>
    <h3>Cloud Native</h3>
    <p>Runs entirely in GitHub Codespaces. Access from any browser, any device, anywhere.</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">🎨</div>
    <h3>Your Choice</h3>
    <p>7 desktop environments. Pick XFCE4 for speed or KDE for features. You decide.</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">💾</div>
    <h3>Persistent</h3>
    <p>Your files survive restarts. Everything in <code>./data/</code> stays safe forever.</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">🔧</div>
    <h3>Customizable</h3>
    <p>Edit <code>config.env</code> to install apps, adjust resources, choose desktops.</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">🚀</div>
    <h3>Optimized</h3>
    <p>Fast variants cut startup time by 40% and size by 30%. Perfect for quick tasks.</p>
  </div>
</div>

---

## ⚡ Instant Start — One Command

<div class="cmd-box">
docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-fast-latest && sleep 2 && echo "🎉 Opening http://localhost:3000..."
</div>

**That's it.** Open your browser. Desktop ready in 30 seconds. ✨

---

## 📦 Choose Your Flavor

### Standard Images ⚙️
Full-featured. Wine, Chrome, recording, audio, backups all enabled.

| Desktop | Image |
|---------|-------|
| 🏃 **XFCE4** (Recommended) | `xfce4-latest` |
| 👑 **KDE** (Full-Featured) | `kde-latest` |
| 🍒 **GNOME** (Modern) | `gnome-latest` |
| 🎨 **Cinnamon** (Windows-like) | `cinnamon-latest` |
| 🪶 **LXQT** (Lightweight) | `lxqt-latest` |
| ⌨️ **i3** (Tiling) | `i3-latest` |
| 🎯 **Budgie** (Minimal) | `budgie-latest` |

### Fast Images ⚡ (New!)
Optimized for speed. Minimal preset, 40% faster startup, 30% smaller size.

| Desktop | Image |
|---------|-------|
| 🔥 **XFCE4** | `xfce4-fast-latest` |
| 🚀 **KDE** | `kde-fast-latest` |
| ⚙️ **GNOME** | `gnome-fast-latest` |
| 🎯 **Cinnamon** | `cinnamon-fast-latest` |
| 💨 **LXQT** | `lxqt-fast-latest` |
| ⌨️ **i3** | `i3-fast-latest` |
| ✨ **Budgie** | `budgie-fast-latest` |

<div class="section-divider"></div>

## 🚀 5-Minute Setup (Traditional)

### 1️⃣ Fork & Open Codespace

Click **Fork** → **Code → Codespaces → Create codespace on main**

> 💡 Use a **4-core machine** for the best experience

### 2️⃣ Customize (Optional)

<div class="cmd-box">
# Edit config.env
FASTVM_TZ=America/New_York
FASTVM_DE=XFCE4
FASTVM_APP_CHROME=true
</div>

### 3️⃣ Install

<div class="cmd-box">
chmod +x fastvm-install.sh
./fastvm-install.sh
</div>

⏳ **First build: 5-15 minutes** (downloads ~2GB)  
☕ Grab coffee — it's normal!

### 4️⃣ Open in Browser

When it finishes, click the **Port 3000** link or go to `http://localhost:3000`

🎉 **Your desktop is ready!**

<div class="section-divider"></div>

## 🖥️ System Requirements

| Machine | RAM | Recommended | Notes |
|---------|-----|-------------|-------|
| **2-core** | 8 GB | XFCE4, LXQT | ✅ Works · Avoid heavy apps |
| **4-core** | 16 GB | XFCE4, KDE, Cinnamon | ✅ Comfortable · Recommended |
| **8-core** | 32 GB | Any | ✅ Smooth · All features shine |

<div class="section-divider"></div>

## ⚙️ Management Commands

```bash
# Start/Stop/Restart
docker-compose up -d      # Start FastVM
docker-compose stop       # Stop (data preserved)
docker-compose restart    # Restart

# Monitor
docker-compose logs -f    # View live logs
docker ps                 # Check if running

# Update
git pull && docker-compose build && docker-compose up -d
```

<div class="section-divider"></div>

## 🛠️ Troubleshooting

**Port not showing?**
→ Wait 60 seconds, refresh browser

**Desktop is slow?**
→ Upgrade to 4-core machine, switch to XFCE4

**Permission denied errors?**
→ `sudo chown -R 1000:1000 ./data`

**Build failed?**
→ `docker-compose down && docker-compose build --no-cache && docker-compose up -d`

<div class="section-divider"></div>

## 📁 What's Inside

```
fastvm/
├── 📋 config.env              ← Customize here
├── 🐳 docker-compose.yml      ← Docker config
├── 📦 Dockerfile.optimized    ← Build recipe
├── 🚀 fastvm-install.sh       ← Quick installer
├── 💾 data/                   ← Your persistent files
├── 📝 logs/                   ← Application logs
└── .github/workflows/         ← CI/CD automation
```

<div class="section-divider"></div>

## 🤝 Contributing

We love contributions! 

- **Code quality:** Use `set -euo pipefail`, no unnecessary `sleep` delays
- **Logging:** Use `log_info`, `log_success`, `log_warn`, `log_error` helpers
- **Testing:** Test across multiple desktops and machine types

<div align="center" style="margin-top: 60px; padding: 40px; background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%); border-radius: 12px;">

## 💝 Love FastVM?

**[⭐ Star us on GitHub](https://github.com/CloudCompile/fastvm/stargazers)**  
**[🐛 Report Issues](https://github.com/CloudCompile/fastvm/issues)**  
**[💬 Start Discussions](https://github.com/CloudCompile/fastvm/discussions)**

---

**Built with ❤️ by [CloudCompile](https://github.com/CloudCompile)**

Based on [BlobeVM](https://github.com/DockSTARTER/blobevmx) · Uses [LinuxServer.io](https://www.linuxserver.io/) base images · Powered by [Docker](https://www.docker.com/)

**MIT License** — See [LICENSE](LICENSE) for details

</div>
