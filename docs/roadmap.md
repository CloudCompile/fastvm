# FastVM roadmap

FastVM follows [semantic versioning](https://semver.org/): features ship in `1.x`
minors, breaking changes bump the major. Each version below is linked to its
**tracking issue**, **milestone**, and **release**. Progress is tracked on the
[FastVM Roadmap project](https://github.com/users/CloudCompile/projects/6).

| Version | Theme | Tracking issue | Milestone | Release |
| --- | --- | --- | --- | --- |
| v1.0.0 | Baseline | [#32](https://github.com/CloudCompile/fastvm/issues/32) | [milestone 1](https://github.com/CloudCompile/fastvm/milestone/1) | [v1.0.0](https://github.com/CloudCompile/fastvm/releases/tag/v1.0.0) |
| v1.1.0 | Node & headless hardening | [#33](https://github.com/CloudCompile/fastvm/issues/33) | [milestone 2](https://github.com/CloudCompile/fastvm/milestone/2) | [planned](https://github.com/CloudCompile/fastvm/milestone/2) |
| v1.2.0 | Audio & input | [#34](https://github.com/CloudCompile/fastvm/issues/34) | [milestone 3](https://github.com/CloudCompile/fastvm/milestone/3) | [planned](https://github.com/CloudCompile/fastvm/milestone/3) |
| v1.3.0 | Bundles & catalog | [#35](https://github.com/CloudCompile/fastvm/issues/35) | [milestone 4](https://github.com/CloudCompile/fastvm/milestone/4) | [planned](https://github.com/CloudCompile/fastvm/milestone/4) |
| v2.0.0 | Streaming stack re-eval | [#36](https://github.com/CloudCompile/fastvm/issues/36) | [milestone 5](https://github.com/CloudCompile/fastvm/milestone/5) | unscheduled |

Release links above resolve once each version is cut. Due dates live on the
milestones; they are targets, not promises.

## v1.0.0 — Baseline (released)

The repository as it ships today. See the
[release notes](https://github.com/CloudCompile/fastvm/releases/tag/v1.0.0)
for the full feature list: browser desktop, dashboard, headless Node.js mode,
distro flavors, GPU stacks, Pterodactyl deployment.

## v1.1.0 — Node & headless hardening

- Security guidance for exposing Node.js app ports
  ([#22](https://github.com/CloudCompile/fastvm/issues/22))
- CI validation of all compose stacks
  ([#23](https://github.com/CloudCompile/fastvm/issues/23))
- Complete the image catalog documentation
  ([#24](https://github.com/CloudCompile/fastvm/issues/24))
- README consistency pass ([#25](https://github.com/CloudCompile/fastvm/issues/25))

## v1.2.0 — Audio & input

- Per-app audio routing ([#26](https://github.com/CloudCompile/fastvm/issues/26))
- Documented gamepad passthrough host workaround
  ([#27](https://github.com/CloudCompile/fastvm/issues/27))
- Documented webcam passthrough host workaround
  ([#28](https://github.com/CloudCompile/fastvm/issues/28))

## v1.3.0 — Bundles & catalog

- Deepen curated app bundles ([#29](https://github.com/CloudCompile/fastvm/issues/29))
- Per-desktop app choices ([#30](https://github.com/CloudCompile/fastvm/issues/30))

## v2.0.0 — Streaming stack re-eval (future)

- Evaluate streaming-stack alternatives with native camera support
  ([#31](https://github.com/CloudCompile/fastvm/issues/31)). Large,
  breaking-leaning change; not scheduled.

## Upstream constraints

Two known limitations are **blocked upstream** in the open-source KasmVNC
base image (`ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy`), and are
handled as documented host-side workarounds rather than image features:

### Webcam passthrough

FastVM streams a container desktop through KasmVNC. That server has no webcam
support — its source tree contains no camera, `v4l2`, or
`getUserMedia`-for-video code. Webcam passthrough is a **Kasm Workspaces**
(commercial) feature. It requires the `allow_kasm_webcam` group setting and the
`v4l2loopback` kernel module loaded on the **host**, neither of which is
available to a plain `docker run` of the LinuxServer base image, and the kernel
module cannot be installed from inside a container.

The workaround is tracked in [#28](https://github.com/CloudCompile/fastvm/issues/28);
the proper fix is the v2.0.0 streaming-stack evaluation
([#31](https://github.com/CloudCompile/fastvm/issues/31)). Until then, video
calls inside FastVM have no camera; audio and microphone do work (see
[discord-vm.md](discord-vm.md)).

### Gamepad passthrough

Same upstream situation as the webcam: Kasm Workspaces supports it, the OSS
base image does not. Workaround documented in
[#27](https://github.com/CloudCompile/fastvm/issues/27).

### Options if upstream support ever lands

1. **Host-side workarounds** (current plan) — per-host manual setup,
   documented in v1.2.0.
2. **Switch streaming stack** to one with native camera support — the v2.0.0
   evaluation.
3. **Track upstream** — if KasmVNC adds browser-camera-to-v4l2, revisit.
