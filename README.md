# FastVM

An optimized, faster version of BlobeVM - a Virtual Machine that runs entirely in your web browser with improved performance, better error handling, and flexible configuration.

## 🚀 Key Improvements Over BlobeVM

| Feature | BlobeVM | FastVM |
|---------|---------|--------|
| Docker Cache | `--no-cache` (slow) | ✅ Cache enabled (fast) |
| Error Handling | Basic | ✅ `set -euo pipefail` |
| Sleep Delays | Multiple delays | ✅ No unnecessary delays |
| Management | Raw docker commands | ✅ Docker Compose |
| APT Operations | Multiple updates | ✅ Single consolidated update |
| JSON Parsing | `jq \| grep` | ✅ jq exit codes |
| Configuration | Hardcoded | ✅ Environment variables |
| App Installation | Sequential | ✅ Parallel processing |
| Health Checks | None | ✅ Built-in health checks |
| Resource Limits | None | ✅ Configurable limits |

## 📋 Requirements

- Docker (with daemon running)
- Docker Compose (v1 or v2)
- Git
- jq (will be auto-installed if missing)
- Linux/macOS/WSL2

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/FastVM.git
cd FastVM
```

### 2. Configure (Optional)

Edit `config.env` to customize your setup:

```bash
# Change the port
FASTVM_PORT=8080

# Change desktop environment
FASTVM_DE=KDE

# Enable KVM acceleration
FASTVM_ENABLE_KVM=true
```

### 3. Install

```bash
chmod +x fastvm-install.sh
./fastvm-install.sh
```

### 4. Access

Open your browser and navigate to `http://localhost:3000` (or your configured port).

## ⚙️ Configuration

All configuration is done through the `config.env` file:

### Network Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `FASTVM_PORT` | 3000 | Web interface port |
| `FASTVM_NAME` | FastVM | Container name |

### User Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `FASTVM_PUID` | 1000 | User ID for file permissions |
| `FASTVM_PGID` | 1000 | Group ID for file permissions |
| `FASTVM_TZ` | Etc/UTC | Timezone |

### Resource Limits

| Variable | Default | Description |
|----------|---------|-------------|
| `FASTVM_SHM_SIZE` | 2gb | Shared memory size |
| `FASTVM_CPU_LIMIT` | 0 | CPU cores (0 = unlimited) |
| `FASTVM_MEMORY_LIMIT` | 0 | Memory limit (0 = unlimited) |

### Desktop Environments

| Variable | Description |
|----------|-------------|
| `FASTVM_DE=KDE` | Full-featured, heavy |
| `FASTVM_DE=XFCE4` | Balanced, lightweight (default) |
| `FASTVM_DE=I3` | Tiling WM, very lightweight |
| `FASTVM_DE=GNOME` | Modern, very heavy |
| `FASTVM_DE=Cinnamon` | Traditional, medium |
| `FASTVM_DE=LXQT` | Lightweight Qt-based |

### Application Selection

```bash
# Default Apps
FASTVM_APP_WINE=true
FASTVM_APP_CHROME=true
FASTVM_APP_DISCORD=true
FASTVM_APP_STEAM=true

# Programming
FASTVM_PROG_VSCODIUM=true

# Additional Apps
FASTVM_APP_LIBREOFFICE=true
```

## 🐳 Docker Compose Commands

FastVM uses Docker Compose for easy management:

```bash
# Start FastVM
docker-compose up -d

# Stop FastVM
docker-compose stop

# Restart FastVM
docker-compose restart

# View logs
docker-compose logs -f

# Update/rebuild
docker-compose build
docker-compose up -d

# Remove completely
docker-compose down
```

## 🔧 Advanced Usage

### Custom Build

```bash
# Build with specific arguments
export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
export VERSION=1.0.0
docker-compose build
```

### Health Checks

FastVM includes built-in health checks:

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' FastVM

# View health check logs
docker inspect --format='{{json .State.Health}}' FastVM | jq
```

### Resource Monitoring

```bash
# View container stats
docker stats FastVM

# View resource limits
docker inspect --format='{{.HostConfig}}' FastVM
```

## 🛠️ Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Verify configuration
docker-compose config

# Check for port conflicts
sudo lsof -i :3000
```

### Permission Issues

```bash
# Fix data directory permissions
sudo chown -R 1000:1000 ./data
```

### Slow Performance

1. Enable KVM acceleration: `FASTVM_ENABLE_KVM=true`
2. Increase shared memory: `FASTVM_SHM_SIZE=4gb`
3. Allocate more resources: `FASTVM_MEMORY_LIMIT=4g`

### Build Failures

```bash
# Clean build (use cache but rebuild)
docker-compose build --no-cache

# Or force rebuild
docker-compose down
docker-compose build
docker-compose up -d
```

## 📁 File Structure

```
FastVM/
├── config.env              # Configuration file
├── docker-compose.yml      # Docker Compose configuration
├── Dockerfile.optimized    # Optimized Dockerfile
├── fastvm-install.sh       # Main installation script
├── fastvm-setup.sh         # Desktop environment setup
├── installapps-parallel.sh # Parallel app installation
├── README.md              # This file
├── data/                  # Persistent data (created on install)
└── logs/                  # Log files (created on install)
```

## 🔒 Security

- Runs in isolated Docker container
- Uses seccomp unconfined for compatibility
- Optional KVM device access (configurable)
- User namespace mapping support

## 📝 Performance Tips

1. **Use Cache**: Never use `--no-cache` unless debugging build issues
2. **Enable KVM**: Set `FASTVM_ENABLE_KVM=true` for better performance
3. **Resource Limits**: Set appropriate CPU/memory limits
4. **SSD Storage**: Use SSD for data directory for better I/O
5. **Network**: Use local network for faster builds

## 🤝 Contributing

Contributions are welcome! Please ensure:

1. Code follows `set -euo pipefail` error handling
2. No unnecessary `sleep` commands
3. Use `jq -e` instead of `jq | grep`
4. Consolidate APT operations
5. Add proper logging

## 📜 License

This project is based on BlobeVM and maintains the same license terms.

## 🙏 Acknowledgments

- Original BlobeVM project
- LinuxServer.io for base images
- Docker and Docker Compose teams
