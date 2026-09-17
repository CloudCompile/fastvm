# FastVM on HiddenCloud Pterodactyl VPS

This guide explains how to deploy FastVM on HiddenCloud's free Pterodactyl VPS tier using the included `app.py` launcher.

## 📋 Prerequisites

- Pterodactyl panel with server access
- 2 vCPU, 3 GB RAM, ~15 GB storage (free tier)
- Python 3.7+ (usually included in panel environments)
- Docker or Podman available/installable

If Docker is not installed in the panel image, `app.py` downloads the official
Docker CLI and Compose plugin into `~/.local/bin` and `~/.docker/cli-plugins`.
This requires outbound HTTPS access and a Docker daemon endpoint such as
`FASTVM_DOCKER_HOST=unix:///run/user/1000/docker.sock`; installing the CLI does
not create a daemon.

## 🚀 Quick Start

### 1. Copy Files to Your Server

Upload these files to your Pterodactyl server:
- `app.py` — Main launcher
- `requirements.txt` — Python dependencies
- `config.env` — Configuration (with `FASTVM_PRESET=hidencloud-free-vps`)
- `docker-compose.yml` — Container orchestration
- All other FastVM files (Dockerfile.optimized, scripts, presets, etc.)

Keep `app.py`, `config.env`, and `docker-compose.yml` in the same directory.
Pterodactyl normally starts processes from `/home/container`; the launcher now
resolves its default project directory from the location of `app.py`, so the
files do not need to be in the panel's current working directory. If the
configuration is stored elsewhere, set `FASTVM_CONFIG_FILE` to its absolute
path or pass `--dir /path/to/fastvm`.

### 2. Install Dependencies

In your Pterodactyl console or SSH terminal:

```bash
# Install Python dependencies
pip install -r requirements.txt

# Make app.py executable
chmod +x app.py
```

### 3. Configure for Your VPS

Edit `config.env`:

```bash
# Essential settings (already optimized in preset)
FASTVM_PRESET=hidencloud-free-vps
FASTVM_PORT=3000
FASTVM_DASHBOARD_HOST_PORT=3001

# Optional: Change timezone
FASTVM_TZ=America/New_York

# Optional: Change desktop (LXQT is default and recommended)
# FASTVM_DE=LXQT
```

### 4. Start FastVM

```bash
python3 app.py start
```

When the panel startup command runs `python3 app.py` with no arguments, the
launcher defaults to `start`.

Wait 30-60 seconds for startup.

## 🌐 Access Your Desktop

### Local Network
- **Desktop**: `http://localhost:3000`
- **Dashboard**: `http://localhost:3001`

### Via Cloudflare Tunnel (Public Access)

Install Cloudflare Tunnel agent:

```bash
# Download and install cloudflared
curl -L --output cloudflared.tgz https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.tgz
tar -xzf cloudflared.tgz

# Authenticate (creates tunnel)
./cloudflared tunnel login

# Create tunnel to FastVM
./cloudflared tunnel create fastvm

# Route to your domain
cloudflared tunnel route dns fastvm yourdomain.com
cloudflared tunnel route dns dashboard.yourdomain.com

# Run tunnel
./cloudflared tunnel run fastvm \
  --url http://localhost:3000 \
  --url http://localhost:3001
```

Then access:
- Desktop: `https://fastvm.yourdomain.com`
- Dashboard: `https://dashboard.yourdomain.com`

## 🎮 Available Commands

```bash
# Start the container
python3 app.py start

# Check container status
python3 app.py status

# View logs (last 50 lines)
python3 app.py logs

# View more logs
python3 app.py logs --lines 200

# Stop the container
python3 app.py stop

# Install Docker if needed
python3 app.py install
```

## ⚙️ Configuration Reference

The `hidencloud-free-vps` preset includes:

| Setting | Value | Reason |
|---------|-------|--------|
| Desktop | LXQT | Lightweight, ~200 MB memory overhead |
| CPU limit | 2 cores | Respect VPS allocation |
| RAM limit | 3 GB | Respect VPS allocation |
| Shared memory | 1 GB | Safe for 3 GB total |
| Wine | Disabled | Saves 1-2 GB storage |
| Chrome | Disabled | Saves ~500 MB storage |
| Audio | Disabled | Saves resources, rarely needed in browser |
| Recording | Disabled | Saves 1+ GB storage monthly |
| Backups | Disabled | Saves storage space |
| Auto-scaling | Disabled | Prevents thrashing on 2 vCPU |

### Customize If Needed

Edit `config.env` for custom settings:

```bash
# Use more memory if available (be careful!)
FASTVM_MEMORY_LIMIT=4g

# Enable optional features (uses more storage)
FASTVM_AUDIO_ENABLED=true
FASTVM_RECORDING_ENABLED=true

# Change to I3 for even lighter (advanced users)
FASTVM_DE=I3

# Install Firefox (already included)
FASTVM_APP_CHROME=false  # Chrome disabled by default
```

## 🐛 Troubleshooting

### "app.py: command not found"
Make sure the file is executable:
```bash
chmod +x app.py
python3 app.py start
```

### "Docker not found"
The launcher attempts to install Docker automatically, but on some systems you may need:
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
```

### "Port 3000 not responding"
1. Wait 60 seconds (building takes time on first start)
2. Check status: `python3 app.py status`
3. Check logs: `python3 app.py logs`
4. Restart: `python3 app.py stop && python3 app.py start`

### "Permission denied" errors
The launcher handles non-root execution. If you see permission errors, try:
```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# May need to logout/login or run:
newgrp docker
```

### Desktop feels slow
1. Ensure nothing else is running: `ps aux`
2. Check available memory: `free -h`
3. Reduce shared memory if consuming too much:
   ```bash
   # In config.env
   FASTVM_SHM_SIZE=512m
   ```

### Can't reach dashboard
Dashboard requires authentication token (for security):
```bash
cat data/dashboard.token
# Use the token in URL: http://localhost:3001?token=<token>
```

## 📊 Performance Expectations

| Metric | Typical Value |
|--------|---------------|
| Boot time | 25-30 seconds |
| Idle RAM | 2.2-2.5 GB |
| Idle CPU | 5-10% |
| Max storage used | 9-12 GB |
| Concurrent users | 1-2 |
| FPS (browser) | 20-30 |

## 🔒 Security Notes

- **Non-root execution**: App runs as unprivileged user
- **Cloudflare Tunnel**: All traffic encrypted end-to-end
- **Local-only by default**: Ports 3000/3001 not exposed to internet
- **Data persistence**: `/data` directory contains everything (backups, recordings, etc.)

## 🆘 Getting Help

1. Check logs: `python3 app.py logs --lines 100`
2. Check Docker logs: `docker-compose logs`
3. Check disk space: `df -h`
4. Check memory: `free -h`
5. Check processes: `docker ps` or `podman ps`

## 📚 Related Documentation

- **Main README**: See repository README.md for full feature list
- **Presets**: See `presets/` directory for other configurations
- **Docker Compose**: Reference `docker-compose.yml` for container settings
- **Scripts**: See `scripts/` for runtime helpers

## 💡 Tips

1. **Save on storage**: Disable unnecessary features in config.env
2. **Improve performance**: Use LXQT or I3 desktop (less overhead)
3. **Access from anywhere**: Use Cloudflare Tunnel
4. **Monitor usage**: Check dashboard at `http://localhost:3001`
5. **Backup data**: Copy `/data` directory regularly

---

**Happy streaming!** 🎉
