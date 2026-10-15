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
