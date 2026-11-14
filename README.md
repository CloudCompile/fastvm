# FastVM

FastVM runs a Linux desktop in a browser using Docker and KasmVNC. Choose from
published desktop/preset images, single-app images, or the FastVM OS appliance.

[![CI builds](https://img.shields.io/github/actions/workflow/status/CloudCompile/fastvm/build-images.yml?branch=main&logo=github-actions)](https://github.com/CloudCompile/fastvm/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Open in Codespaces](https://img.shields.io/badge/open%20in-Codespaces-181717?logo=github)](https://codespaces.new/CloudCompile/fastvm)

## Quick start

Run a published desktop image:

```bash
docker run -d \
  --name fastvm \
  -p 3000:3000 \
  -p 3001:8099 \
  -v "$PWD/data:/config" \
  ghcr.io/cloudcompile/fastvm:xfce4-none-latest
```

Open [http://localhost:3000](http://localhost:3000). The management dashboard
is available at [http://localhost:3001](http://localhost:3001).

For a local build with persistent data and configuration:

```bash
cp config.env.example config.env
./fastvm-install.sh
```

## Choose a deployment

| Need | Start here |
| --- | --- |
| Published desktop image | [`docs/deployment.md`](docs/deployment.md) |
| GitHub Codespaces | [`docs/codespaces.md`](docs/codespaces.md) |
| Headless Node.js server | [`docs/nodejs.md`](docs/nodejs.md) |
| Pterodactyl or a constrained VPS | [`docs/pterodactyl.md`](docs/pterodactyl.md) |
| Image and tag catalog | [`docs/image-catalog.md`](docs/image-catalog.md) |
| Benchmark results | [`docs/benchmarks.md`](docs/benchmarks.md) |

## What is included

- Browser-streamed Linux desktop on port `3000`
- Optional management dashboard on port `3001`
- Persistent configuration and application data under `/config`
- Backups, recordings, clipboard support, audio, and performance monitoring
- Published images for multiple desktop environments and app presets
- GPU, Codespaces, gaming, and single-app deployment options

The default image is intended for interactive desktop sessions. For a server
that should start without KasmVNC or any GUI, use the separate headless stack
documented in [`docs/nodejs.md`](docs/nodejs.md).

## Configuration and security

Runtime settings are in `config.env`; start from
[`config.env.example`](config.env.example). Validate changes with:

```bash
scripts/validate-config.sh
```

Do not expose the desktop or dashboard directly to the public internet. Use
HTTPS and an authenticated reverse proxy, protect `data/dashboard.token`, and
leave privileged mode disabled unless the workload requires it. See
[`SECURITY.md`](SECURITY.md).

## Documentation

- [`docs/deployment.md`](docs/deployment.md) — Docker, Compose, builds, and ports
- [`docs/nodejs.md`](docs/nodejs.md) — Node.js servers, including headless mode
- [`docs/image-catalog.md`](docs/image-catalog.md) — published images and tags
- [`docs/app-bundles.md`](docs/app-bundles.md) — presets and application bundles
- [`docs/codespaces.md`](docs/codespaces.md) — Codespaces setup and limits
- [`docs/pterodactyl.md`](docs/pterodactyl.md) — constrained VPS deployment
- [`docs/performance.md`](docs/performance.md) — tuning and machine sizing
- [`docs/gpu.md`](docs/gpu.md) — GPU rendering and hardware encoding
- [`docs/audio.md`](docs/audio.md) — browser audio and microphone support
- [`docs/discord-vm.md`](docs/discord-vm.md) — Discord-only image
- [`docs/gaming.md`](docs/gaming.md) — gaming support and limitations
- [`docs/benchmarks.md`](docs/benchmarks.md) — benchmark methodology
- [`docs/roadmap.md`](docs/roadmap.md) — known limitations and planned work
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution and validation guidance

## Contributing

Keep pull requests focused and document configuration or security changes.
Run the relevant checks before opening a PR; see
[`CONTRIBUTING.md`](CONTRIBUTING.md).

FastVM is MIT licensed.
