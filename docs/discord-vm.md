# FastVM Discord VM

A minimal, single-purpose image that runs **only Discord**: no desktop
environment, no distribution application packages. It is the base KasmVNC image
plus openbox, a few Electron runtime libraries, and the Discord `.deb` unpacked
straight into the filesystem.

## Run it

```bash
docker run -d --name fastvm-discord -p 3000:3000 \
  --shm-size=2g \
  ghcr.io/cloudcompile/fastvm:discord-latest
```

Open <http://localhost:3000>. Discord launches fullscreen in an openbox session.

> The `--shm-size` is not optional. Chromium keeps render surfaces in
> `/dev/shm`; the Docker default is 64 MB, which makes Discord fall back to
> slow paths or crash on video. Keep it at least 512 MB; 2 GB is comfortable.

## What is actually installed

| Layer | Contents |
| --- | --- |
| Base | `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy` (KasmVNC, PulseAudio, kclient, nginx) |
| Window manager | `openbox` |
| Electron runtime | `libatomic1`, `libgbm1`, `libasound2` |
| App | Discord `.deb`, unpacked with `dpkg -i` |

`dpkg -i` installs exactly the contents of the `.deb` — it does **not** resolve
dependencies from the Ubuntu archive. The three libraries above are the only
additions beyond the base image. See `installable-apps/discord-only.sh`.

## Sound and microphone

Both directions work, and they are provided by the base image rather than by
FastVM:

- **Sound out** — PulseAudio plus the `kclient` PCM player over websocket.
- **Microphone in** — `kclient` calls `getUserMedia` on your *browser's* mic and
  streams it over websocket into the container, where it is loaded as a
  PulseAudio source named `virtmic` (`svc-kclient`).

### Requirements

1. **Grant browser permission.** The browser prompts for microphone access the
   first time. Denying it leaves Discord with no input device.
2. **Secure context.** Browsers only expose `getUserMedia` on `localhost` or over
   HTTPS. On a remote host you must terminate TLS in front of port 3000, or the
   microphone will be silently unavailable.
3. **Open the KasmVNC audio panel** and enable the microphone if it is off.

### Verifying audio in a running container

```bash
docker exec fastvm-discord /fastvm-scripts/audio-self-test.sh
```

This discovers the default sink and source, plays a short tone, and captures
samples. The single-app session also logs the audio input state at startup:

```text
[fastvm] audio input ready: default source=virtmic
```

## Webcam

**Not supported.** Webcam passthrough is a Kasm **Workspaces** (commercial)
feature that requires the `v4l2loopback` kernel module on the host and Kasm's own
web platform. The open-source KasmVNC server that this image streams from has no
webcam code at all. Discord video calls will see no camera. See
[roadmap.md](roadmap.md).

## Getting the most out of the machine

Discord is Electron (Chromium + Node). Its throughput is gated by three things,
none of which are "more CPU threads":

### 1. Give the container the resources it needs

The default `config.env` used to cap the container at **2 CPUs / 8 GB**, which
wastes half of a 4-core/16 GB host. `FASTVM_CPU_LIMIT` and `FASTVM_MEMORY_LIMIT`
now default to `0` (no cap — the container sees the whole machine).

A fixed CPU cap also has a side effect worth knowing: it limits the browser's
*microphone* thread pool (Discord's own `config.json` can set `videoCapture` and
`audioCapture` thread counts, but Chromium caps them by the CPU count it sees).
Home **2c/8g** and **4c/16g** boxes have plenty for voice; the cap just needs to
not be below the real core count.

### 2. Launch flags tuned to the box

`scripts/discord-tune.sh` detects the actual CPU/memory/GPU budget and prints
the flags. The single-app session appends them to Discord's autostart command:

```bash
# no GPU (2c/8g or 4c/16g)
--autoplay-policy=no-user-gesture-required \
--num-raster-threads=N --renderer-process-limit=<cpus> \
--disable-gpu --in-process-gpu --disable-lcd-text \
--enable-features=WebRtcAllowInputVolumeAdjustment,WebRTC-PiggybackOptimization \
[--disable-dev-shm-usage]   # only when /dev/shm is under 512 MB

# graphics GPU (adds hardware decode)
... --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy \
--enable-features=...,VaapiVideoDecoder,VaapiVideoEncoder
```

Inspect it on any machine:

```bash
docker exec fastvm-discord /fastvm-scripts/discord-tune.sh report
```

`--num-raster-threads` is derived from the measured CPU budget, so it neither
starves a 2-core box nor over-subscribes a large one.

### 3. Shared memory

Chromium keeps render surfaces in `/dev/shm`. A small value makes it fall back
to slow paths or crash. FastVM raises it to 4 GB (`FASTVM_SHM_SIZE`) and the
tuner only adds `--disable-dev-shm-usage` when the container's `/dev/shm` is
actually under 512 MB.

## GPU

On a compute-only accelerator (for example an AMD Instinct MI300X) Discord runs
on CPU rasterization (`llvmpipe`). That is expected and does not affect chat or
voice. See [gpu.md](gpu.md).

## Related

- [audio.md](audio.md) — FastVM audio model
- [image-catalog.md](image-catalog.md) — all image variants
- [roadmap.md](roadmap.md) — webcam passthrough and other planned work
