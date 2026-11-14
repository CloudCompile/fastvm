# Deployment

## Published images

The quickest deployment uses a published image from GitHub Container Registry:

```bash
docker run -d \
  --name fastvm \
  -p 3000:3000 \
  -p 3001:8099 \
  -v "$PWD/data:/config" \
  ghcr.io/cloudcompile/fastvm:xfce4-none-latest
```

Port `3000` serves the KasmVNC desktop. Port `3001` maps to the dashboard's
internal port `8099`. The dashboard token is stored in
`data/dashboard.token`.

Image names follow these patterns:

- `<desktop>-<preset>-latest`
- `<single-app>-latest`
- `fastvm-os-latest` (FastVM appliance flavor)

See the [image catalog](image-catalog.md) for supported values.

## Docker Compose

Copy the example configuration, adjust it, validate it, and start the stack:

```bash
cp config.env.example config.env
scripts/validate-config.sh
docker compose up -d --build
```

The main Compose file builds `Dockerfile.fastvm-preset` (the shared
`fastvm-base` image is pulled from GHCR and only the preset layer is built)
unless `FASTVM_IMAGE` is set to a published image. Runtime data is stored in
`data/`, `backups/`, `recordings/`, and `logs/`.

Use the installer when you want the repository's build, image-selection, and
startup flow:

```bash
./fastvm-install.sh
./fastvm-install.sh --pull
./fastvm-install.sh --no-build
./fastvm-install.sh --print-image
```

## Build directly

```bash
docker build -f Dockerfile.fastvm-preset \
  --build-arg FASTVM_BASE_IMAGE=ghcr.io/cloudcompile/fastvm:base-latest \
  --build-arg FASTVM_DE=XFCE4 \
  --build-arg FASTVM_PRESET=development \
  -t fastvm:local .

docker run -d -p 3000:3000 -p 3001:8099 fastvm:local
```

Building the shared base yourself instead of pulling it:

```bash
docker build -f Dockerfile.fastvm-base -t fastvm-base:local .
# then add --build-arg FASTVM_BASE_IMAGE=fastvm-base:local to the preset build
```

## GPU and FastVM OS appliance

Use the documented Compose overlay for GPU access:

```bash
FASTVM_GPU=amd ./fastvm-install.sh
FASTVM_GPU=nvidia ./fastvm-install.sh
```

FastVM publishes one product-specific appliance flavor, `fastvm-os`. Desktop
environments such as XFCE, KDE, Cinnamon, and GNOME are available as ordinary
FastVM image variants; they are not separate upstream Linux distributions.
See [image-catalog.md](image-catalog.md).

## Port reference

| Host port | Container port | Purpose |
| ---: | ---: | --- |
| `3000` | `3000` | KasmVNC desktop |
| `3001` | `8099` | Management dashboard |
| `3002` | `3002` | Optional in-image Node.js server |

Change host ports with `FASTVM_PORT`,
`FASTVM_DASHBOARD_HOST_PORT`, and `FASTVM_NODE_SERVER_HOST_PORT`.
