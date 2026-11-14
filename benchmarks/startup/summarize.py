#!/usr/bin/env python3
"""Aggregate benchmark results into a markdown table.

Usage: python3 summarize.py [results-dir]   (default: benchmarks/startup/results)
"""

import json
import sys
from pathlib import Path

METRICS = ["pull", "build", "create", "start_cold", "dash_cold", "start_stopped", "restart"]
METRIC_LABELS = {
    "pull": "pull (s)",
    "build": "build (s)",
    "create": "create (s)",
    "start_cold": "cold start (s)",
    "dash_cold": "dashboard (s)",
    "start_stopped": "start stopped (s)",
    "restart": "restart (s)",
}


def fmt(v):
    if isinstance(v, (int, float)):
        return f"{v:.2f}" if isinstance(v, float) else str(v)
    return "—" if v is None else str(v)


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent / "results")
    rows = []
    for mode_dir in sorted(root.iterdir()):
        if not mode_dir.is_dir():
            continue
        for f in sorted(mode_dir.glob("*.json")):
            d = json.loads(f.read_text())
            rows.append(d)

    rows.sort(key=lambda d: (d["mode"], d["preset"], d["host"]["cpu_count"], d["host"]["ram_mb"]))

    print("| Mode | Preset | vCPU | RAM | " + " | ".join(METRIC_LABELS[m] for m in METRICS) + " | Idle (RAM/CPU) | Complete |")
    print("| --- | --- | --- | --- | " + " --- |" * (len(METRICS) + 1))

    for d in rows:
        h = d.get("host", {})
        vals = " | ".join(fmt(d.get(m)) for m in METRICS)
        idle = d.get("idle_stats", "—")
        comp = "✓" if d.get("complete") else "✗"
        print(f"| {d['mode']} | {d['preset']} | {h.get('cpu_count')} | "
              f"{round(h.get('ram_mb', 0) / 1024, 1)} GB | {vals} | {idle} | {comp} |")


if __name__ == "__main__":
    main()
