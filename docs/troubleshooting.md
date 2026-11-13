# Troubleshooting

## Check container state

```bash
docker ps
docker compose ps
docker compose logs -f fastvm
```

## Desktop port does not load

Confirm that the container is running and that the host port is not already in
use. The default desktop URL is `http://localhost:3000`. Initial startup can
take longer for a local build or a large preset.

## Dashboard is unavailable

The dashboard is on host port `3001` and listens inside the container on
`8099`:

```bash
curl -f http://localhost:3001/api/health
cat data/dashboard.token
```

Use the token with the `Authorization: Bearer` header for authenticated API
requests.

## Node.js server is unavailable

For the headless service:

```bash
docker compose -f docker-compose.node.yml ps
docker compose -f docker-compose.node.yml logs -f
```

Check that the application is under `data/node-app`, has a valid
`package.json`, honors `PORT`, and binds to `0.0.0.0`.

## Configuration changes are ignored

Recreate the stack after changing `config.env`:

```bash
docker compose down
docker compose up -d
```

Validate the file before restarting:

```bash
scripts/validate-config.sh
```

## Slow desktop

Use a lighter desktop or preset, increase shared memory, and review the
automatic performance profile:

```env
FASTVM_DE=XFCE4
FASTVM_PRESET=minimal
FASTVM_SHM_SIZE=4gb
FASTVM_PERF_PROFILE=auto
```

See [performance.md](performance.md) and [gpu.md](gpu.md) for deeper tuning.
