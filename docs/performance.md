# FastVM performance profile

FastVM is designed to run where it is cheap to run: a GitHub Codespace, a small
VPS, a home server. The machine it lands on is often far smaller than the image
assumes — the reference target is **2 vCPU / 8 GB RAM / no GPU**. On those hosts
there is no `/dev/dri`, so the desktop is rasterized by Mesa's software driver
(`llvmpipe`), and the defaults are tuned for a workstation, not for two cores.

`scripts/perf-profile.sh` measures the resources the container actually has,
classifies the host, and derives the settings that suit it. It runs at container
startup (via `root/etc/cont-init.d/99-fastvm-init`) and again from the desktop
session (`scripts/gpu-session-env.sh`).

## What it changes

| Knob | Small host | Why |
|:--|:--|:--|
| `LIBGL_ALWAYS_SOFTWARE=1`, `GALLIUM_DRIVER=llvmpipe` | set when there is no graphics GPU | Pin the software path so Mesa does not probe a GPU that is not there |
| `LP_NUM_THREADS` | = vCPU count | llvmpipe otherwise parallelises across *all* host CPUs and thrashes a 2-core box |
| `MESA_GLTHREAD=true` | set | Keep GL calls off the app's main thread |
| `vblank_mode=0`, `__GL_SYNC_TO_VBLANK=0` | set | Do not block GL apps on a vertical sync they cannot see |
| `FASTVM_PERF_ENCODE_THREADS` | vCPU − 1 (min 1) | The screen recorder leaves a core for the desktop |
| Desktop compositing | off | Re-compositing frames that are streamed away is pure CPU cost |

The GPU path is never touched: when a graphics GPU is present the profile emits
no software-render overrides and leaves compositing alone (`docs/gpu.md` owns the
GPU story).

## Profiles

`classify()` maps the measured budget to a profile:

| Profile | When | Effect |
|:--|:--|:--|
| `constrained` | ≤ 2 vCPU **or** ≤ 4 GB RAM | full software tuning + compositor off |
| `balanced` | ≤ 4 vCPU **or** ≤ 8 GB RAM | full software tuning + compositor off |
| `performance` | anything larger | no overrides (a workstation needs no help) |

Override with `FASTVM_PERF_PROFILE` in `config.env` if the automatic choice is
wrong for your host.

## Inspecting it

Inside the container:

```bash
perf-profile.sh report   # human-readable summary
perf-profile.sh json     # machine-readable record (also at /config/.fastvm/perf-profile.json)
perf-profile.sh env      # the KEY=VALUE exports for this host
perf-profile.sh bench    # time a software encode at the derived thread count
```

The record is exposed to the dashboard at `GET /api/system/status` under `perf`.

## Honest measurement

`bench` times a fixed `libx264` encode at the derived thread count versus the
library default and prints both. It is a local sanity check, not a benchmark
claim: a near-tie means the clamp is free on that host. Per the project's
benchmarking policy (`docs/benchmarks.md`), numbers belong in CI artifacts, not
in marketing copy.

## Test hooks

The classifier and the environment derivation are pure functions of the measured
budget, so CI can pin them without a small host:

| Variable | Effect |
|:--|:--|
| `FASTVM_PERF_FORCE_CPUS` | pretend the container has this many vCPUs |
| `FASTVM_PERF_FORCE_MEM_MB` | pretend the container has this much RAM |
| `FASTVM_PERF_FORCE_SHM_MB` | pretend `/dev/shm` is this size |
| `FASTVM_PERF_FORCE_GPU_KIND` | pretend the GPU kind is `graphics`, `compute`, or `none` |

The `validate-perf-profile` CI job asserts, for a simulated 2-core / 8 GB no-GPU
host, that the profile is `constrained`, that llvmpipe is clamped to the vCPU
count, that the encoder leaves a core free, and that a graphics GPU is never
forced onto the software path.
