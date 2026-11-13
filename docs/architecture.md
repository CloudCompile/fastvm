# Architecture

FastVM is built around a LinuxServer KasmVNC base image.

```text
Browser
  │
  ├── host :3000 → KasmVNC desktop :3000
  ├── host :3001 → FastVM dashboard :8099
  └── host :3002 → optional Node.js app :3002
       │
       └── persistent ./data → /config
```

## Image layers

1. The KasmVNC base image and runtime startup
2. FastVM desktop setup
3. Optional applications and presets
4. FastVM runtime scripts
5. The Node.js management dashboard
6. Optional distro identity layers

## Runtime services

- KasmVNC and the selected desktop provide the browser session.
- The dashboard provides health, metrics, backups, recording, clipboard, and
  system APIs.
- The optional in-image Node.js service runs a user project from
  `/config/node-app`.
- `docker-compose.node.yml` is independent and starts only the headless Node.js
  service.

## Persistent data

The default Compose deployment stores:

- `data/` — dashboard token, runtime metadata, and application data
- `backups/` — scheduled and manual snapshots
- `recordings/` — screen recordings
- `logs/` — FastVM logs

Do not commit these directories, tokens, dependency directories, or generated
build output.
