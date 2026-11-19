# FastVM Benchmarks

Benchmark values must be measured on a documented host and should not be treated
as guarantees. Record image, host CPU/RAM, Docker version, image size, startup
time, dashboard health time, desktop readiness time, idle RAM, idle CPU, and
application launch time.

Example command set:

```bash
time docker compose up -d
curl --fail --retry 20 --retry-delay 2 http://localhost:3001/api/health
docker stats --no-stream FastVM
```

CI should publish measurements as artifacts instead of hard-coding startup
claims in marketing documentation.

## Host performance profile

`scripts/perf-profile.sh` classifies the host from its measured CPU/RAM and
derives software-render, encoder-thread, and compositor settings (see
`docs/performance.md`). Its `bench` mode times a fixed `libx264` encode at the
derived thread count versus the library default so the clamp can be checked
locally; the classifier itself is pinned by the `validate-perf-profile` CI job
using the `FASTVM_PERF_FORCE_*` test hooks, with no small host required.

## Measured startup matrix (alpha, 2026-11-13)

Measured on e2b sandboxes (Intel Xeon 2.60 GHz, kernel 6.1.189, Docker 27.5.1)
across the six supported XFCE4 presets × vCPU {1, 2, 4, 8} × RAM {1, 2, 4, 8 GB} —
192 runs: 96 from the published GHCR image, 96 built from source. Raw JSON:
[`benchmarks/startup/results/`](../benchmarks/startup/results/), full table:
[`results/SUMMARY.md`](../benchmarks/startup/results/SUMMARY.md).
Run it yourself: `python3 benchmarks/startup/orchestrate.py build-templates`
then `orchestrate.py run --mode prebuilt|build` (needs `E2B_API_KEY`).

### Headline numbers (medians)

| Scenario | Pull / build | Create | Cold start | Start stopped | Restart |
| --- | --- | --- | --- | --- | --- |
| Prebuilt image | 49–105 s pull | 0.16 s | 2.0 s | 1.6 s | 1.6 s |
| Built from source | 120–440 s build | 0.05 s | 2.4 s | 1.6 s | 1.6 s |

### Findings

- **Pull dominates prebuilt provisioning.** ~1.24 GiB of compressed layers
  takes 50–105 s; everything after the pull is ~2 s. Caching/prewarming the
  image on a persistent host removes nearly the entire provisioning cost.
- **Container lifecycle is config-independent.** Create, start-from-stopped,
  and restart medians are ~1.6 s across the entire grid. RAM (1–8 GB) barely
  matters; 1 vCPU adds roughly 0.5–1 s to first boot versus 4+ vCPU.
- **Idle footprint is small**: ~185–230 MiB RAM and 3–5% CPU per session
  after startup settles, independent of preset.
- **Build-from-source time is network-bound, not CPU-bound** (mostly `apt`
  downloads), so build time does not scale strongly with the sandbox size.
  Expect 2–8 minutes per build.
- **Image size** is ~2.98 GB (`none`/`minimal`) to ~3.28 GB (heavier presets)
  extracted — the shared runtime dominates, which is what the
  [shared-base experiment](https://github.com/CloudCompile/fastvm/pull/39)
  targets: persistent hosts pull the shared base once and reuse it for every
  preset.
