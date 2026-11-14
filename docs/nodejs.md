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

The app listens on a published port. **Do not expose that port directly to the
public internet.** Terminate HTTPS and require authentication at a reverse
proxy. These examples assume Caddy or Nginx runs on the Docker host and proxies
to `127.0.0.1:3002`.

The standalone headless Compose service binds the **host side** to loopback by
default (`FASTVM_NODE_SERVER_BIND_IP=127.0.0.1`), while the app itself binds to
`0.0.0.0` inside the container so Docker can reach it. You do not need a port
override. Only set `FASTVM_NODE_SERVER_BIND_IP=0.0.0.0` if you intentionally
want direct network access and have a firewall/security layer in place.

```bash
docker compose -f docker-compose.node.yml up -d
```

This binds the published host port to loopback, so it is not directly reachable
from other machines. Keep the firewall closed for port `3002` as an additional
safeguard.

### Caddy (automatic HTTPS + Basic Auth)

Create a password hash with `caddy hash-password`, then configure a site:

```caddyfile
node.example.com {
    basic_auth {
        {$FASTVM_PROXY_USER} {$FASTVM_PROXY_PASSWORD_HASH}
    }
    reverse_proxy 127.0.0.1:3002
}
```

Set `FASTVM_PROXY_USER` and `FASTVM_PROXY_PASSWORD_HASH` in the Caddy service's
environment (use the generated hash, not a plaintext password). Point the
domain's DNS at the host and allow inbound ports `80` and `443` for Caddy's
automatic certificate management.

### Nginx (TLS + Basic Auth)

Create the password file with `sudo htpasswd -c /etc/nginx/fastvm.htpasswd USER`
and configure the TLS server. Replace the certificate paths with certificates
managed by your ACME client:

```nginx
server {
    listen 443 ssl;
    server_name node.example.com;

    ssl_certificate     /etc/letsencrypt/live/node.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/node.example.com/privkey.pem;

    auth_basic "FastVM Node app";
    auth_basic_user_file /etc/nginx/fastvm.htpasswd;

    location / {
        proxy_pass http://127.0.0.1:3002;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Redirect HTTP to HTTPS and allow inbound `443` (and `80` only if needed for
ACME/redirects). Keep the app's published port loopback-only. Do not mount the
Docker socket into the application container. Authentication at the proxy is
an example; use your organization's identity-aware proxy if available.
