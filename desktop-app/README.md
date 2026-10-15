# FastVM Marketplace (desktop app)

A **Tauri 2** desktop client for FastVM. Browse a marketplace of ready-to-run
Linux desktops and distros, then launch any of them with **one click** — no
terminal required. Runs on Linux, Windows, and macOS.

```
┌──────────────────────────────────────────────────────────────┐
│  ⚡ FastVM Marketplace        [ search… ]        Docker 27.x   │
│  [Featured][Desktops][Gaming][Distros][Minimal][All]          │
│ ┌──────────────┐ ┌──────────────┐   ┌───────────────────────┐ │
│ │ pearOS    ★  │ │ Kali         │   │ pearOS                │ │
│ │ macOS-like   │ │ Security     │   │ macOS-inspired KDE    │ │
│ │ [Deploy]     │ │ [Deploy]     │   │ port 3000  [⚡ Deploy] │ │
│ └──────────────┘ └──────────────┘   └───────────────────────┘ │
│ Running instances · 1                                          │
│ pearOS  running   ghcr.io/…:pearos-latest  [Open][Logs][Stop] │
└──────────────────────────────────────────────────────────────┘
```

## Features

- **Full catalog** — every published variant (36 desktops × 6 presets, 16 distro
  flavors, and 4 single-app images: 236 images), grouped by category and
  searchable. A curated set carries hand-written names and taglines.
- **One-click deploy** — pick an app, tweak ports / name / shared memory / GPU,
  and launch it. The container starts and the desktop opens in your browser.
- **Exact command preview** — the `docker run` line is produced by the backend
  (`preview_run_args`), so it always matches what a deploy executes. Copy it
  with one click.
- **GPU awareness** — the header shows the detected host GPU and its available
  acceleration modes; the passthrough selector is only offered when a `/dev/dri`
  device exists.
- **GPU acceleration modes** — pick the right flags for the host: **DRM**
  (`--device /dev/dri`) for Intel/AMD graphics, **ROCm** (`/dev/dri` + `/dev/kfd`
  + `--group-add keep-groups`) for AMD compute, or **NVIDIA** (`--gpus all`) when
  the container toolkit is present. The recommended mode is preselected.
- **Mode-aware environment** — each mode also sets the container-side variables
  from `docs/gpu.md` (`FASTVM_GPU_HW`, `FASTVM_RECORDING_ENCODER`, `DISABLE_DRI`,
  `NVIDIA_DRIVER_CAPABILITIES`) so the desktop and encoder actually use the
  device. Your own `-e` values are appended after and therefore win.
- **Encoder picker** — the video encoder (`nvenc`, `qsv`, `vaapi`, `software`) is
  chosen per vendor: Intel defaults to Quick Sync, NVIDIA to NVENC, AMD to VA-API.
- **Host warnings** — the backend flags missing NVIDIA container toolkit and
  compute-only accelerators (e.g. MI300X) in the details panel.
- **Device details** — the GPU status click-through lists each card with its
  kernel driver (`amdgpu`/`i915`/`nvidia`) and, where the kernel exposes it, VRAM.
- **Verify in container** — a button shows the `nvidia-smi` / `rocm-smi` /
  `vainfo` commands that prove the chosen mode is delivering the GPU.
- **Compose output** — the same deploy renders as a `docker-compose.yml` service
  (with the GPU stanza and environment) alongside the `docker run` command.
- **Advanced run options** — set memory and CPU limits, environment variables,
  and bind mounts; all flow into the previewed command.
- **Deploy profiles** — snapshot the whole deploy config (ports, GPU mode,
  encoder, limits, env, volumes) under a name per app and re-apply it later.
  Stored locally; handy for "the way I always run this one".
- **Custom images** — a **＋ Custom image** entry deploys any container image by
  reference (`ghcr.io/me/app:tag`, a private registry), not just catalog tags.
  The reference is validated in the backend before it reaches Docker.
- **Remote Docker hosts** — the header shows where the CLI actually deploys. If
  `DOCKER_HOST` / `DOCKER_CONTEXT` point at an `ssh://` or `tcp://` daemon, the
  app says so (and warns) instead of silently shipping containers elsewhere.
- **Visible pull** — deploy pulls the image first and reports whether it was
  downloaded or already local, so the long first-run wait is no longer a stall.
- **Instance manager** — see running containers with **Open / Dashboard / Logs /
  Stop / Remove**, refreshed automatically, with live CPU/memory stats and
  live-tailing logs. **Stop all** shuts down every running instance at once.
- **Favorites & sorting** — star apps (persisted locally) and sort by Featured,
  name, or lightest-first.
- **Keyboard shortcuts** — `Ctrl/⌘+K` or `/` focuses search, `Esc` closes the
  log view.
- **Docker awareness** — the header shows the detected Docker version, or a
  clear warning when Docker is missing.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) installed and running.
- To build from source: the [Rust toolchain](https://rustup.rs/) and the
  [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/) for your OS
  (on Linux: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libayatana-appindicator3-dev`,
  `librsvg2-dev`, `libxdo-dev`).

## Run

```bash
cd desktop-app
npm install          # installs the Tauri CLI
npm run dev          # run in development
```

## Build installers

```bash
npm run build        # .deb / .AppImage / .msi / .dmg, depending on the OS
```

Icons live in `src-tauri/icons/` and are generated by `scripts/gen-icons.py`
(standard-library Python only).

## Architecture

```
desktop-app/
  src/                     frontend (plain HTML/CSS/JS, no bundler)
    index.html
    styles.css
    renderer.js            marketplace UI + one-click deploy
  test/
    renderer.test.js       jsdom tests driving the real UI
  src-tauri/
    src/main.rs            thin entry point
    src/lib.rs             Tauri builder + command registration
    src/catalog.rs         image catalog, marketplace model, docker run builder
    src/gpu.rs             host GPU detection + acceleration modes (DRM/ROCm/NVIDIA)
    src/docker.rs          Docker CLI wrapper + pure parsers
    src/commands.rs        the commands the frontend may call
    capabilities/default.json
    tauri.conf.json
```

The Rust side owns the catalog and every Docker call; the frontend only calls
the commands in `commands.rs`. Those commands are the entire attack surface.

## Security

- The renderer has **no Node, shell, or filesystem access**. It talks to Rust
  through Tauri's typed `invoke` bridge only.
- Docker is invoked with an explicit argument vector via `std::process::Command`
  — never a shell — so catalog or user input cannot be interpreted as shell
  syntax.
- `deploy` validates the requested tag against the catalog before starting a
  container, so only published images can be launched.
- A strict Content-Security-Policy is set in `tauri.conf.json`.

## Tests

```bash
npm test                          # everything below, in order
npm run test:rust                 # 36 Rust unit tests
npm run test:ui                   # 16 jsdom frontend tests
npm run verify                    # catalog in sync with the CI build matrix
```

The pure logic (tag builders, `docker run` args for every GPU mode, `docker ps`
and `docker stats` parsing, port selection, tag validation, GPU vendor mapping,
mode selection) is unit-tested without needing Docker or a display. The frontend
tests load the real `index.html` + `renderer.js` into jsdom with a stubbed
`invoke` bridge and drive the UI the way a user would (search, sort, star,
select, pick a GPU mode, set advanced options, open logs).
