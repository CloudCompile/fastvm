# Pterodactyl and constrained VPS

FastVM includes `app.py` for deployments where a panel starts a process as a
non-root user. The launcher detects Docker or Podman, prepares persistent
directories, loads `config.env`, and starts the Compose stack.

## Setup

Upload the project files, including `app.py`, `requirements.txt`,
`config.env`, `docker-compose.yml`, and the Docker build context. Install the
Python dependency:

```bash
pip install -r requirements.txt
chmod +x app.py
```

Configure a constrained profile:

```env
FASTVM_PRESET=none
FASTVM_DE=LXQT
FASTVM_PORT=3000
FASTVM_DASHBOARD_HOST_PORT=3001
FASTVM_CPU_LIMIT=2
FASTVM_MEMORY_LIMIT=3g
FASTVM_SHM_SIZE=1gb
```

Start and manage FastVM with:

```bash
python3 app.py start
python3 app.py status
python3 app.py logs
python3 app.py stop
```

If the panel's working directory differs from the uploaded files, set:

```bash
FASTVM_CONFIG_FILE=/absolute/path/config.env python3 app.py start
```

## Cloudflare Tunnel

Terminate public access at HTTPS and forward only the ports you need. For
example:

```bash
cloudflare-tunnel run \
  --url http://localhost:3000 \
  --url http://localhost:3001 \
  my-fastvm-tunnel
```

The free VPS profile is intended for one or two light users. It disables
resource-heavy extras and should not be treated as a general production
cluster.
