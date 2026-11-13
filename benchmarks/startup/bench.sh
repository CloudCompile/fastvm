#!/usr/bin/env bash
# FastVM startup benchmark — runs INSIDE an e2b sandbox.
#
# Usage: bash bench.sh <mode> <preset> <results-json-path>
#   mode:   prebuilt | build
#   preset: none | minimal | development | gaming | office | content-creation
#
# prebuilt: times `docker pull` of the published image, then the lifecycle.
# build:    times a full `docker build` from the checked-out repo, then the
#           same lifecycle.
#
# Lifecycle measured (all timings in seconds):
#   create           docker create
#   start_cold       docker start -> first HTTP 200 on :3000 (desktop)
#   dash_cold        docker start -> first 200 on :8099/api/health (dashboard)
#   start_stopped    stop, then docker start -> ready again
#   restart          docker restart -> ready again
#
# The sandbox is expected to be sized via its e2b template; host info is
# recorded in the results. Exits non-zero if any lifecycle step fails.
set -uo pipefail

MODE="${1:?mode: prebuilt|build}"
PRESET="${2:?preset required}"
OUT="${3:?results path required}"

DOCKER="/usr/local/bin/docker"
REPO="/home/user/fastvm"
READY_TIMEOUT=900          # seconds to wait for desktop readiness
POLL_INTERVAL=0.5

log() { echo "[bench] $*"; }
docker() { sudo "$DOCKER" "$@"; }
now() { date +%s.%N; }
trap 'touch /tmp/bench.done' EXIT   # orchestrator polls for this

# --------------------------------------------------------------- environment
HOST_INFO="$(python3 - <<'PY'
import json, os, subprocess
def sh(c):
    try:
        return subprocess.run(c, shell=True, capture_output=True, text=True).stdout.strip()
    except Exception as e:
        return str(e)
mem = {}
for line in open('/proc/meminfo'):
    k, _, v = line.partition(':')
    mem[k.strip()] = int(v.strip().split()[0]) if v.strip() else 0
print(json.dumps({
    'cpu_count': os.cpu_count(),
    'cpu_model': sh("grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'"),
    'ram_mb': round(mem.get('MemTotal', 0) / 1024),
    'disk_free_gb': round(int(sh("df -BG / | tail -1 | awk '{print $4}'").rstrip('G'))),
    'kernel': sh('uname -r'),
    'docker_version': sh('/usr/local/bin/docker --version 2>/dev/null || echo missing'),
}))
PY
)"
log "host: $HOST_INFO"

ensure_daemon() {
  if ! docker info > /dev/null 2>&1; then
    log "starting dockerd"
    sudo sh -c 'nohup /usr/local/bin/dockerd --iptables=false --bridge=none > /tmp/dockerd.log 2>&1 &'
    for _ in $(seq 1 90); do
      docker info > /dev/null 2>&1 && return 0
      sleep 2
    done
    log "dockerd failed to start"; return 1
  fi
}
ensure_daemon || exit 1
log "dockerd ready: $(docker version --format '{{.Server.Version}}' 2>/dev/null)"

# ------------------------------------------------------------------ helpers
# poll_ready <url> <deadline-seconds>; echoes elapsed seconds or "timeout"
poll_ready() {
  local url="$1" deadline_sec="$2" t0 rc i=0 el
  t0="$(now)"
  local deadline=$(( $(date +%s) + deadline_sec ))
  while (( $(date +%s) < deadline )); do
    rc="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" 2>/dev/null || true)"
    if [[ "$rc" == "200" ]]; then
      python3 -c "print(round($(now) - $t0, 2))"
      return 0
    fi
    i=$((i + 1))
    # keep stdout streaming so long polls do not idle out the connection
    if (( i % 30 == 0 )); then
      el="$(python3 -c "print(round($(now) - $t0, 1))")"
      echo "[bench]   waiting for $url (${el}s)"
    fi
    sleep "$POLL_INTERVAL"
  done
  echo "timeout"
  return 1
}

declare -A T   # timings

# ------------------------------------------------------------------- image
if [[ "$MODE" == "prebuilt" ]]; then
  IMAGE="ghcr.io/cloudcompile/fastvm:xfce4-${PRESET}-latest"
  t0="$(now)"
  if ! docker pull -q "$IMAGE" > /tmp/pull.log 2>&1; then
    log "PULL FAILED"; tail -5 /tmp/pull.log; exit 1
  fi
  T[pull]="$(python3 -c "print(round($(now) - $t0, 2))")"
  log "pull: ${T[pull]}s"
else
  cd "$REPO" || exit 1
  IMAGE="fastvm:bench-xfce4-${PRESET}"
  t0="$(now)"
  if ! docker build -f Dockerfile.optimized -t "$IMAGE" \
      --network host \
      --build-arg "BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --build-arg "VERSION=bench" \
      --build-arg "FASTVM_DE=xfce4" \
      --build-arg "FASTVM_PRESET=${PRESET}" \
      . > /tmp/build.log 2>&1; then
    log "BUILD FAILED"; tail -20 /tmp/build.log; exit 1
  fi
  T[build]="$(python3 -c "print(round($(now) - $t0, 2))")"
  log "build: ${T[build]}s"
fi

IMAGE_SIZE="$(docker image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null || echo 0)"
IMAGE_DIGEST="$(docker image inspect "$IMAGE" --format '{{index .RepoDigests 0}}' 2>/dev/null || echo "$IMAGE")"

# --------------------------------------------------------------- lifecycle
docker rm -f fastvm-bench > /dev/null 2>&1

t0="$(now)"
CREATE_OK="$(docker create --name fastvm-bench --network host "$IMAGE" > /dev/null 2>&1 && echo ok || echo fail)"
T[create]="$(python3 -c "print(round($(now) - $t0, 2))")"
[[ "$CREATE_OK" == "ok" ]] || { log "CREATE FAILED"; exit 1; }
log "create: ${T[create]}s"

t0="$(now)"
docker start fastvm-bench > /dev/null 2>&1 || true
log "docker start issued (+$(python3 -c "print(round($(now) - $t0, 2))")s)"
# dashboard readiness is polled concurrently with the desktop
( poll_ready http://localhost:8099/api/health "$READY_TIMEOUT" > /tmp/dash.elapsed 2>&1 ) &
DASH_PID=$!
cold_desktop="$(poll_ready http://localhost:3000/ "$READY_TIMEOUT")"
wait "$DASH_PID" || true
cold_dash="$(tail -1 /tmp/dash.elapsed 2>/dev/null || echo missing)"
T[start_cold]="$cold_desktop"
T[dash_cold]="$cold_dash"
log "start_cold(desktop): ${T[start_cold]}s  dash: ${T[dash_cold]}s"

sleep 15  # let startup churn settle before sampling idle usage
IDLE_STATS="$(docker stats --no-stream --format '{{.MemUsage}} {{.CPUPerc}}' fastvm-bench 2>/dev/null | head -1 || echo unknown)"

docker stop -t 30 fastvm-bench > /dev/null 2>&1
sleep 3

t0="$(now)"
stopped_desktop="$( { docker start fastvm-bench > /dev/null 2>&1 && poll_ready http://localhost:3000/ "$READY_TIMEOUT"; } || echo fail )"
T[start_stopped]="$stopped_desktop"
log "start_stopped: ${T[start_stopped]}s"

t0="$(now)"
restart_desktop="$( { docker restart -t 30 fastvm-bench > /dev/null 2>&1 && poll_ready http://localhost:3000/ "$READY_TIMEOUT"; } || echo fail )"
T[restart]="$restart_desktop"
log "restart: ${T[restart]}s"

LOGS_TAIL="$(docker logs --tail 10 fastvm-bench 2>&1 | tr '\n' ' ' | tail -c 500 || true)"
docker rm -f fastvm-bench > /dev/null 2>&1

# ------------------------------------------------------------------ output
export BENCH_MODE="$MODE" BENCH_PRESET="$PRESET" BENCH_IMAGE="$IMAGE_DIGEST"
export BENCH_IMAGE_SIZE="${IMAGE_SIZE:-0}" BENCH_IDLE_STATS="$IDLE_STATS"
export BENCH_LOGS_TAIL="$LOGS_TAIL" BENCH_HOST_INFO="$HOST_INFO"
export BENCH_PULL="${T[pull]:-missing}" BENCH_BUILD="${T[build]:-missing}"
export BENCH_CREATE="${T[create]:-missing}" BENCH_START_COLD="${T[start_cold]:-missing}"
export BENCH_DASH_COLD="${T[dash_cold]:-missing}"
export BENCH_START_STOPPED="${T[start_stopped]:-missing}" BENCH_RESTART="${T[restart]:-missing}"
python3 - "$OUT" <<'PY'
import json, os, sys

def value(name):
    raw = os.environ.get(name, "missing")
    try:
        return float(raw) if raw not in ("missing", "timeout", "fail") else raw
    except ValueError:
        return raw

result = {
    "mode": os.environ["BENCH_MODE"],
    "preset": os.environ["BENCH_PRESET"],
    "image": os.environ["BENCH_IMAGE"],
    "image_size_bytes": int(os.environ.get("BENCH_IMAGE_SIZE", "0")),
    "idle_stats": os.environ.get("BENCH_IDLE_STATS", "unknown"),
    "logs_tail": os.environ.get("BENCH_LOGS_TAIL", ""),
    "host": json.loads(os.environ["BENCH_HOST_INFO"]),
}
for key, env_name in (
    ("pull", "BENCH_PULL"), ("build", "BENCH_BUILD"),
    ("create", "BENCH_CREATE"), ("start_cold", "BENCH_START_COLD"),
    ("dash_cold", "BENCH_DASH_COLD"),
    ("start_stopped", "BENCH_START_STOPPED"), ("restart", "BENCH_RESTART"),
):
    result[key] = value(env_name)
with open(sys.argv[1], "w") as f:
    json.dump(result, f, indent=2)
    f.write("\n")
PY

# Sanity: JSON must be valid
python3 -c "import json;json.load(open('$OUT'))" || { log "JSON INVALID"; cat "$OUT"; exit 1; }

failed=0
for k in start_cold start_stopped restart; do
  [[ "${T[$k]}" =~ ^[0-9.]+$ ]] || failed=1
done
log "done: $(cat "$OUT" | tr -d '\n' | head -c 400)"
exit $failed
