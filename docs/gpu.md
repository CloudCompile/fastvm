# FastVM GPU acceleration

FastVM runs without a GPU by default and falls back to software encoding and
software (llvmpipe) desktop rendering. When the host has a GPU, FastVM can use it
for **real GPU rasterization of the desktop**, hardware video encode, and
GPU-accelerated applications. Every GPU feature is opt-in: a host with no GPU
behaves exactly as before.

There are three places a GPU helps:

1. **Desktop rendering** — KasmVNC's DRI3 mode (`-hw3d`) makes the X server
   rasterize the desktop on the GPU instead of CPU RAM, so GL/3D apps and the
   composited desktop stop falling back to `llvmpipe`.
2. **Screen recording** — `ffmpeg` hardware encode (NVENC / VA-API / QSV)
   replaces `libx264` and frees CPU for the desktop.
3. **Applications** — Blender, ML/CUDA, and DXVK/Proton games use the GPU
   directly once the device nodes are mapped.

## What "real GPU rasterization" means here

FastVM's desktop is drawn by Xvnc, a *virtual* X server that normally allocates
the screen in system RAM and renders GL with Mesa's software rasterizer
(`llvmpipe`). Mapping `/dev/dri` alone does not change that — the X server has to
be told to use the GPU. The base image handles the server side automatically:
when `/dev/dri` is present (and NVIDIA's `nvidia-smi` is **not**), it starts Xvnc
with `-hw3d`, which enables **DRI3** and makes the GPU the render device for the
whole session. FastVM then sets the per-session userspace variables
(`scripts/gpu-session-env.sh`) so applications pick the same GPU.

DRI3 has two requirements worth knowing:

- **Compositing must be off.** KasmVNC does not support desktop compositing with
  DRI3; with it on, the window manager still falls back to `llvmpipe`. See
  [Desktop compositing](#desktop-compositing) below.
- **Open-source drivers only.** Intel and AMD work directly. NVIDIA's closed
  driver has no DRI3 and is reached through **Zink** (OpenGL-over-Vulkan)
  instead.

## 1. Enable GPU access (compose overlays)

Do **not** set `FASTVM_PRIVILEGED=true`. Use the overlays, which map only the
needed devices. With the installer, set `FASTVM_GPU` in `config.env` and run
`./fastvm-install.sh` — it selects the right overlay automatically:

| `FASTVM_GPU`        | Effect                                              |
| ------------------- | --------------------------------------------------- |
| `false` (default)   | No device mapping; software encoding only.          |
| `true` / `intel` / `amd` | Map `/dev/dri` for DRI3/VA-API/QSV.           |
| `nvidia`            | NVIDIA device reservation (needs the container toolkit). |

The equivalent manual commands are below.

### Intel / AMD (VA-API, QSV, DRI3)

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

This maps `/dev/dri` and adds the `video`/`render` groups. Verify inside the
container:

```text
vainfo
ffmpeg -hide_banner -encoders | grep -E 'vaapi|qsv'
```

### NVIDIA (NVENC)

Host prerequisite: install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
and run `nvidia-ctk runtime configure --runtime=docker`, then restart Docker.

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu-nvidia.yml up -d
```

NVENC needs the `video` capability; CUDA/ML needs `compute`. The overlay sets
`NVIDIA_DRIVER_CAPABILITIES=compute,video,utility` by default. Verify:

```text
nvidia-smi
ffmpeg -hide_banner -encoders | grep nvenc
```

## Compute-only accelerators (AMD Instinct / CDNA)

Some GPUs do compute but have **no graphics engine** — for example the AMD
Instinct **MI300X** (CDNA 3). These expose a DRM *render* node (`/dev/dri/renderD*`)
but no KMS *card* node, no display output, and no OpenGL/Vulkan pipeline
(`radeonsi`/RADV do not support CDNA). Their video blocks are reachable through
ROCm (`rocDecode`), not VA-API.

On such a host:

- **Games and GPU desktop rasterization are not possible** — there is no graphics
  pipeline to use. The desktop renders on the CPU (`llvmpipe`).
- `/dev/dri` and `/dev/kfd` are still worth mapping for **ROCm compute**
  (PyTorch/HIP/llama.cpp).
- KasmVNC must **not** try DRI3, and the VA-API path is unusable.

FastVM detects this case automatically: `scripts/gpu-detect.sh` records
`"compute_only": true` in `gpu.json`, recommends the **software** encoder, and the
session helper skips DRI3/compositing. To also stop KasmVNC from attempting DRI3
at all, set `DISABLE_DRI=1` (the base image skips `-hw3d` when it is set):

```bash
docker run -d --name fastvm-mi300x \
  --device=/dev/kfd --device=/dev/dri \
  --group-add video --group-add render \
  -e DISABLE_DRI=1 -e FASTVM_GPU_HW=false -e FASTVM_RECORDING_ENCODER=software \
  -p 3000:3000 -p 3001:8099 \
  ghcr.io/cloudcompile/fastvm:xfce4-gaming-latest
```

Verify:

```text
docker exec fastvm-mi300x ls -l /dev/dri /dev/kfd          # compute nodes present
docker exec -e DISPLAY=:1 fastvm-mi300x glxinfo -B | grep -i renderer   # llvmpipe (expected)
docker exec fastvm-mi300x rocm-smi                          # once ROCm userspace is installed
```

> NVIDIA compute accelerators (A100/H100) likewise have no display engine and are
> not GPU-rasterized, though NVENC is available; only the desktop stays on the CPU.

## 2. Choose an encoder

Set `FASTVM_RECORDING_ENCODER` in `config.env`:

| Value      | Behaviour                                                        |
| ---------- | ---------------------------------------------------------------- |
| `auto`     | Use the encoder detected at startup; fall back to software.      |
| `nvenc`    | Force NVIDIA NVENC (`h264_nvenc`).                               |
| `vaapi`    | Force VA-API (`h264_vaapi`) — Intel/AMD.                         |
| `qsv`      | Force Intel Quick Sync (`h264_qsv`).                             |
| `software` | Force `libx264` (CPU).                                           |

Hardware encoders produce H.264, so `auto` forces an H.264-capable container
(`mp4`/`mkv`) even if `FASTVM_RECORDING_FORMAT` asks for `webm`.

## 4. Desktop compositing

KasmVNC's DRI3 mode does **not** support desktop compositing: with the
compositor enabled, the window manager (and therefore the whole desktop) renders
through `llvmpipe` on the CPU even when a GPU is mapped. So for GPU rasterization
to be *real*, compositing has to be off.

`FASTVM_GPU_HW=true` (set by the GPU overlays) sources
`scripts/gpu-session-env.sh` into the session. On an open-source GPU (Intel/AMD)
the helper:

1. exports the GPU render node (`LIBVA_DRM_DEVICE`) so applications use it, and
2. **disables desktop compositing** for the desktops that support it, so the
   window manager rasterizes on the GPU instead of `llvmpipe`.

| Desktop | Compositing handled how |
| ------- | ----------------------- |
| XFCE    | Disabled automatically (`xfwm4 /general/use_compositing=false`) |
| KDE     | Disabled automatically (`kwinrc [Compositing] Enabled=false`) |
| MATE    | Disabled automatically (`marco compositing-manager=false`) |
| GNOME   | Not supported; GNOME is forced to use `llvmpipe` |
| Others  | Left as-is (no compositor or no setting); apps still use the GPU |

To keep compositing and window effects anyway, set
`FASTVM_GPU_KEEP_COMPOSITING=true` — the desktop then renders on the CPU, while
GPU compute, hardware encode, and application rendering still work.

> On NVIDIA the compositor is left untouched: the closed driver has no DRI3, so
> there is no rasterization to unlock and the session uses Zink instead (below).

## 5. Detection, status, and self-test

At container start, `scripts/gpu-detect.sh` probes for a GPU and writes
`/config/.fastvm/gpu.json`:

```text
/fastvm-scripts/gpu-detect.sh detect   # probe now
/fastvm-scripts/gpu-detect.sh show     # print the record
```

A short encoder self-test runs at startup (disable with
`FASTVM_GPU_SELFTEST=false`) and warns if a selected hardware encoder fails:

```text
/fastvm-scripts/gpu-self-test.sh          # test the resolved encoder
/fastvm-scripts/gpu-self-test.sh nvenc    # test a specific encoder
```

Check what the session exported for GPU access:

```text
/fastvm-scripts/gpu-session-env.sh --print
```

The dashboard shows GPU utilization/VRAM on the overview and the detected GPU +
encoder under **System → GPU acceleration**. Endpoints:

- `GET /api/gpu/status` — capabilities from `gpu.json`
- `GET /api/gpu/metrics` — live metrics (utilization/VRAM for NVIDIA)
- `GET /api/system/status` — includes a `gpu` object

## 6. Images

The GPU-enabled image ships the VA-API/Mesa/Vulkan userspace drivers:

```bash
docker run --rm --device /dev/dri:/dev/dri \
  ghcr.io/cloudcompile/fastvm:gpu-latest
```

`FASTVM_ENABLE_GPU_DRIVERS=true` (default) installs the driver packages at build
time. NVIDIA does not need packages in the image: the toolkit injects the driver
from the host at runtime.

## 7. Desktop app

The Tauri desktop app (`desktop-app/`) mirrors all of the above without you
having to remember the flags:

- It detects the host GPU (render node, `/dev/kfd`, NVIDIA container toolkit,
  compute-only parts) and offers only the modes the host can actually use.
- The recommended mode is preselected, and picking it injects the matching
  device flags **and** the container-side environment from this document
  (`FASTVM_GPU_HW`, `FASTVM_RECORDING_ENCODER`, `DISABLE_DRI`,
  `NVIDIA_DRIVER_CAPABILITIES`). Any `-e` you add in *Advanced options* is
  appended after, so it overrides the mode default.
- The previewed `docker run` and generated `docker-compose.yml` both include the
  mode's devices and environment.
- **Verify in container** shows the exact `rocm-smi` / `nvidia-smi` / `vainfo` /
  `glxinfo` commands to confirm the GPU is in use.

## Limitations

- **Compute-only accelerators** (AMD Instinct/CDNA, e.g. MI300X; NVIDIA compute
  parts) have no graphics engine: no DRI3 rasterization and (for AMD) no VA-API.
  FastVM detects these (`compute_only` in `gpu.json`) and falls back to CPU
  rasterization and software encode; ROCm compute still works. See above.
- DRI3 acceleration covers the **open-source** Intel and AMD drivers. NVIDIA's
  closed driver has no DRI3; on NVIDIA the desktop itself is not GPU-rasterized,
  and GPU access is limited to compute, hardware encode, and application
  rendering via Zink/Vulkan.
- Desktop compositing and DRI3 are mutually exclusive (see above). GNOME cannot
  disable compositing, so it always renders on the CPU.
- The screen is still a virtual framebuffer in RAM, so there is a per-frame copy
  from GPU to RAM for the stream. The win is that rasterization happens on the
  GPU instead of `llvmpipe`.
- Hardware encode and DRI3 depend on the host driver and the mapped device nodes;
  when either is missing FastVM logs the failure and uses software paths.
- GPU passthrough is a host/operator decision. FastVM never enables privileged
  mode on its own.
