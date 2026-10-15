# FastVM on GitHub Codespaces

FastVM runs a streamed Linux desktop, so a Codespace needs Docker-in-Docker and
a forwarded port. The repository ships a `.devcontainer/`, so a Codespace is
one click: open the repo in Codespaces and the XFCE4 desktop appears on port
3000, with the dashboard on 3001.

## What happens on start

| Hook | Command | Purpose |
|------|---------|---------|
| `onCreateCommand` | `docker pull <published image>` | Pulls the image. Runs at prebuild time and is snapshotted. |
| `postCreateCommand` | `./fastvm-install.sh --no-build` | Starts FastVM. Falls back to a local build if the pull did not happen. |
| `postStartCommand` | `docker compose up -d` | Recreates the container on every resume. Idempotent. |

The image is pulled, not built. Every desktop/preset is already published to
`ghcr.io/cloudcompile/fastvm`, so this is the difference between a desktop in
about a minute and a ~30 minute local build.

## Prebuilds (recommended)

A Codespaces **prebuild** runs `onCreateCommand` when the configuration changes
and snapshots the result. Because the pull happens in `onCreateCommand`, a
prebuilt Codespace starts with the image already present - no pull at all.

To enable prebuilds for a repository: **Settings → Codespaces → Prebuild
configuration → Set up prebuild**, target the default branch, and choose the
2-core (free) machine type. Prebuilds are free for public repositories.

## Choosing a desktop or preset

Edit `.devcontainer/devcontainer.json` and change `FASTVM_DE`, `FASTVM_PRESET`
and `FASTVM_IMAGE` together so the pulled tag matches:

```jsonc
"containerEnv": {
  "FASTVM_IMAGE": "ghcr.io/cloudcompile/fastvm:kde-development-latest",
  "FASTVM_DE": "KDE",
  "FASTVM_PRESET": "development"
}
```

The tag is `<desktop>-<preset>-latest` (lowercase); single-app images are
`<app>-latest`. `./fastvm-install.sh --print-image` prints the tag that
`--pull` would use for the current configuration, which is the quickest way to
check a name before editing the file.

## Machine sizes

The devcontainer requires the free tier (2 cores / 8 GB) so the default
Codespace can create. FastVM auto-tunes for that size (`docs/performance.md`):

- llvmpipe is capped to the core count, and a core is reserved for the recorder.
- Desktop compositing is turned off when the host is small.

A 4-core / 16 GB machine is smoother for heavy presets (gaming, content
creation). Raise `hostRequirements.cpus` only if you also want to force users
onto a paid machine type.

## What Codespaces does not have

`scripts/env-report.sh` measures these at container start and the result is
exposed at `GET /api/system/status` under `environment`. On a standard
Codespace you will see:

- **No `/dev/kvm`.** Hardware virtualisation is unavailable, so VMs and
  emulator guests (Android, aqemu) run in software and are slow. There is no
  workaround inside a Codespace; use a host with nested virtualisation for
  those workloads.
- **Small `/dev/shm`.** FastVM requests 4 GB for its own container
  (`FASTVM_SHM_SIZE`), so Chromium/Electron apps inside FastVM are fine. If you
  run a Chromium-based tool directly in the Codespace (outside FastVM) and it
  crashes, add `--disable-dev-shm-usage` or raise `--shm-size`.
- **No GPU.** GPU passthrough is a host feature; Codespaces machines are
  CPU-only, so FastVM selects the software encoder.

## Persistence and idle timeout

- Codespaces stops an idle Codespace after the configured timeout (30 minutes
  by default, up to 4 hours). `postStartCommand` brings FastVM back on resume.
- FastVM data lives under `./data`, `./backups`, `./recordings`, and `./logs`
  in the repository, which is part of the Codespace filesystem and survives
  stop/start but not deletion.
- Secrets belong in Codespaces secrets, not in `config.env`, which is
  committed. Codespaces secrets are available as environment variables and are
  not written to logs.

## Without the devcontainer

If you already have a Codespace with Docker available, the fast path is:

```bash
./fastvm-install.sh --pull        # pull the image for FASTVM_DE/FASTVM_PRESET
./fastvm-install.sh --no-build    # use an image that is already present
./fastvm-install.sh --print-image # show which image --pull would use
```

## Diagnostics

```bash
./fastvm-install.sh --print-image       # which published tag this config maps to
docker compose logs -f fastvm           # container logs
cat data/.fastvm/environment.json       # host report (kind, kvm, shm, notices)
curl -s localhost:3001/api/system/status -H "Authorization: Bearer $(cat data/dashboard.token)"
```
