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
