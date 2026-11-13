# Node.js servers

FastVM supports two different Node.js deployment modes.

## Headless server (recommended for backend workloads)

This mode does not start KasmVNC, a desktop environment, or the FastVM
dashboard. Put the application in `data/node-app` with a `package.json`, then
start the standalone Node.js Compose service:

```bash
docker compose -f docker-compose.node.yml up -d
```

The service uses the official Node.js 22 image, mounts `data/node-app` at
`/app`, installs production dependencies when `node_modules` is absent, and
runs `npm start` by default. It listens on port `3002`.

Stop it with:

```bash
docker compose -f docker-compose.node.yml down
```

Supported settings:

```env
FASTVM_NODE_SERVER_COMMAND='npm start'
FASTVM_NODE_SERVER_PORT=3002
FASTVM_NODE_SERVER_HOST_PORT=3002
FASTVM_NODE_SERVER_HOST=0.0.0.0
NODE_ENV=production
```

The application must honor the `PORT` environment variable. Bind to
`0.0.0.0`, not only `localhost`, so Docker port publishing can reach it.

## Node.js server inside the desktop image

Enable the in-image service when the Node.js app should run alongside the
desktop and management dashboard:

```env
FASTVM_NODE_SERVER_ENABLED=true
FASTVM_NODE_SERVER_COMMAND='npm start'
FASTVM_NODE_SERVER_PORT=3002
FASTVM_NODE_SERVER_HOST_PORT=3002
```

Place the project in `data/node-app`, then start the normal FastVM Compose
stack. The process runs as the unprivileged `abc` user and receives `PORT` and
`HOST`.

This mode consumes the desktop image's resources. Use the headless mode when
you do not need a browser desktop.

## Security

The application port is published directly. Put it behind an authenticated
HTTPS reverse proxy before exposing it outside a trusted network. Do not mount
the Docker socket into the application container.
