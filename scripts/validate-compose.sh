#!/usr/bin/env bash
# Validate every docker-compose stack in the repository.
#
# Usage: scripts/validate-compose.sh
#
# - Files in FULL_STACKS are validated standalone.
# - Every other docker-compose*.yml is an overlay: it is validated layered on
#   top of the base docker-compose.yml, which is how the docs tell users to
#   run it (e.g. `docker compose -f docker-compose.yml -f docker-compose.kali.yml up -d`).
# - The NVIDIA overlay is additionally validated stacked on the GPU overlay,
#   matching the usage in docs/gpu.md.
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

compose() {
  docker compose "$@" config --quiet
}

# Full stacks: runnable as-is. Overlays: everything else.
FULL_STACKS=("docker-compose.yml" "docker-compose.node.yml")

# Extra layerings to check explicitly: overlay -> extra file(s) stacked on top
# of the base before the overlay itself.
NVIDIA="docker-compose.gpu-nvidia.yml"
GPU="docker-compose.gpu.yml"

fail=0
checked=0

check() {
  local label="$1"; shift
  if compose "$@"; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    fail=1
  fi
  checked=$((checked + 1))
}

for stack in "${FULL_STACKS[@]}"; do
  [[ -f "$stack" ]] || { echo "FAIL missing full stack: $stack"; fail=1; checked=$((checked + 1)); continue; }
  check "$stack" -f "$stack"
done

for overlay in docker-compose*.yml; do
  [[ -f "$overlay" ]] || continue
  for stack in "${FULL_STACKS[@]}"; do
    if [[ "$overlay" == "$stack" ]]; then
      continue 2
    fi
  done
  check "base + $overlay" -f docker-compose.yml -f "$overlay"
done

# NVIDIA layered on the VA-API overlay, per docs/gpu.md.
if [[ -f "$GPU" && -f "$NVIDIA" ]]; then
  check "base + $GPU + $NVIDIA" -f docker-compose.yml -f "$GPU" -f "$NVIDIA"
fi

echo "checked $checked compose stack(s)"
if ((fail)); then
  echo "compose validation FAILED"
  exit 1
fi
echo "compose validation passed"
