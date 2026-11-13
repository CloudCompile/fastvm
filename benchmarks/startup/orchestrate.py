#!/usr/bin/env python3
"""FastVM startup-benchmark orchestrator.

Drives the e2b benchmark: builds one sandbox template per vCPU/RAM config,
then runs benchmarks/startup/bench.sh inside concurrent sandboxes and
collects per-run JSON results.

Prerequisites:
  - pip install e2b (v2 SDK)
  - E2B_API_KEY in the environment

Usage:
  # one-time: build the 16 sized templates (vCPU {1,2,4,8} x RAM {1,2,4,8} GB)
  python3 orchestrate.py build-templates

  # prebuilt-image runs (pull + create/start, start-from-stopped, restart)
  python3 orchestrate.py run --mode prebuilt --workers 90

  # build-from-source runs (docker build + same lifecycle)
  python3 orchestrate.py run --mode build --workers 32

Results are written to benchmarks/startup/results/<mode>/<preset>-c<cpu>-<ram>.json
"""

import argparse
import concurrent.futures as futures
import json
import os
import sys
import threading
import time
from pathlib import Path

from e2b import Sandbox

PRESETS = ["none", "minimal", "development", "gaming", "office", "content-creation"]
CPU_CONFIGS = [1, 2, 4, 8]
RAM_CONFIGS = [1024, 2048, 4096, 8192]  # MiB

BENCH_SCRIPT = Path(__file__).parent / "bench.sh"
RESULTS_DIR = Path(__file__).parent / "results"
TEMPLATE_PREFIX = "fastvm-bench"
BENCH_BRANCH = "main"  # branch cloned inside build-mode sandboxes

_print_lock = threading.Lock()


def log(msg):
    with _print_lock:
        print(f"[orchestrate] {msg}", flush=True)


# --------------------------------------------------------------------------
# templates
# --------------------------------------------------------------------------

TEMPLATE_DOCKERFILE = """FROM e2bdev/base
RUN sudo apt-get update -qq && sudo apt-get install -y -qq curl git \\
 && curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.5.1.tgz \\
 | tar -xz -C /tmp && \\
    for b in docker dockerd containerd runc docker-init docker-proxy containerd-shim-runc-v2; do \\
      sudo install -m 755 /tmp/docker/$b /usr/local/bin/$b; done && \\
    sudo rm -rf /var/lib/apt/lists/*
"""

# start/ready commands are defined below, after _existing_templates().

def _builder_sandbox(timeout_s, attempts=4):
    last = None
    for attempt in range(attempts):
        sbx = Sandbox.create(timeout=timeout_s)
        try:
            r = sbx.commands.run(
                "sudo apt-get update -qq > /dev/null 2>&1; "
                "sudo apt-get install -y -qq curl ca-certificates > /dev/null 2>&1; "
                "curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/ns.sh; "
                "sudo bash /tmp/ns.sh > /dev/null 2>&1; "
                "sudo apt-get install -y -qq nodejs > /dev/null 2>&1; "
                "sudo ln -sf /usr/bin/node /usr/local/bin/node; "
                "sudo npm install -g @e2b/cli --no-audit --no-fund --silent > /dev/null 2>&1; "
                "node --version; e2b --version",
                timeout=900,
                envs={"E2B_API_KEY": os.environ["E2B_API_KEY"]},
            )
            if r.exit_code == 0 and "2" in r.stdout:  # CLI prints a bare version string
                return sbx
            last = (r.stdout + r.stderr)[-300:]
            log(f"builder setup failed (attempt {attempt + 1}): {last}")
        except Exception as e:  # noqa: BLE001
            last = str(e)[:300]
            log(f"builder error (attempt {attempt + 1}): {last}")
        sbx.kill()
        time.sleep(5)
    raise RuntimeError(f"could not set up builder sandbox: {last}")


def _existing_templates(sbx):
    r = sbx.commands.run(
        "e2b template list -f json", timeout=120,
        envs={"E2B_API_KEY": os.environ["E2B_API_KEY"]},
    )
    try:
        items = json.loads(r.stdout)
        if isinstance(items, dict):
            items = items.get("templates", [])
        out = {}
        for t in items if isinstance(items, list) else []:
            tid = t.get("templateId") or t.get("templateID") or t.get("id")
            names = t.get("names") or []
            aliases = t.get("aliases") or []
            key = aliases[0] if aliases else (names[0].split("/")[-1] if names else None)
            if tid and key:
                out[key] = tid
        return out
    except Exception:
        return {}


# start/ready commands passed to `e2b template create`. The start command
# boots dockerd (host networking, no iptables) when the sandbox starts.
START_CMD = 'sudo sh -c "nohup /usr/local/bin/dockerd --iptables=false --bridge=none > /tmp/dockerd.log 2>&1 &"'
READY_CMD = "sudo /usr/local/bin/docker info > /dev/null 2>&1"


def build_templates():
    """One builder sandbox creates every sized template (remote builds)."""
    sbx = _builder_sandbox(timeout_s=3600)
    try:
        existing = _existing_templates(sbx)
        sbx.files.write("/home/user/tpl/e2b.Dockerfile", TEMPLATE_DOCKERFILE)
        for cpu in CPU_CONFIGS:
            for ram in RAM_CONFIGS:
                name = f"{TEMPLATE_PREFIX}-c{cpu}-m{ram}"
                if name in existing:
                    log(f"template {name} exists ({existing[name]})")
                    continue
                cmd = (
                    f"mkdir -p /home/user/tpl && cd /home/user/tpl && e2b template create {name} "
                    f"--dockerfile e2b.Dockerfile "
                    f"--cpu-count {cpu} --memory-mb {ram} "
                    f"--cmd '{START_CMD}' --ready-cmd '{READY_CMD}' 2>&1 | tail -4"
                )
                log(f"building template {name} ({cpu} vCPU / {ram} MiB)...")
                inner_start = START_CMD.replace('"', "'")
                res = sbx.commands.run(
                    f"mkdir -p /home/user/tpl && cd /home/user/tpl && "
                    f"e2b template create {name} "
                    f"--dockerfile e2b.Dockerfile "
                    f"--cpu-count {cpu} --memory-mb {ram} "
                    f"--cmd \"{inner_start}\" "
                    f"--ready-cmd \"{READY_CMD}\"",
                    timeout=1800,
                    envs={"E2B_API_KEY": os.environ["E2B_API_KEY"]},
                )
                out = (res.stdout + res.stderr)
                if res.exit_code != 0 or "Build failed" in out or "ERROR" in out:
                    last = out.strip().splitlines()[-1][:200] if out.strip() else ""
                    log(f"FAILED {name} (exit {res.exit_code}): {last}")
                else:
                    log(f"built {name}")
        templates = _existing_templates(sbx)
    finally:
        sbx.kill()
    return templates


def get_templates():
    sbx = _builder_sandbox(timeout_s=1200)
    try:
        return _existing_templates(sbx)
    finally:
        sbx.kill()


# --------------------------------------------------------------------------
# runs
# --------------------------------------------------------------------------

def run_one(mode, preset, cpu, ram, template_id):
    tag = f"{preset}-c{cpu}-m{ram}"
    out_path = RESULTS_DIR / mode / f"{tag}.json"
    if out_path.exists():
        return  # already done (resumable)
    sbx = None
    started = time.time()
    try:
        sbx = Sandbox.create(template=template_id, timeout=6 * 3600, request_timeout=180)
        sbx.files.write("/home/user/bench.sh", BENCH_SCRIPT.read_text())
        if mode == "build":
            r = sbx.commands.run(
                f"git clone --depth 1 --branch {BENCH_BRANCH} "
                "https://github.com/CloudCompile/fastvm.git /home/user/fastvm",
                timeout=600,
            )
            if r.exit_code != 0:
                raise RuntimeError("clone failed: " + (r.stdout + r.stderr)[-300:])

        # Detached run: bench.sh writes /home/user/result.json when finished.
        # We poll for it instead of holding a long command stream open.
        r = sbx.commands.run(
            "rm -f /home/user/result.json /tmp/bench.done; "
            "nohup bash /home/user/bench.sh "
            f"{mode} {preset} /home/user/result.json > /tmp/bench.log 2>&1 & "
            "echo started",
            timeout=120,
        )
        if "started" not in (r.stdout or ""):
            raise RuntimeError("bench kickoff failed: " + (r.stdout + r.stderr)[-300:])

        deadline = time.time() + 5.5 * 3600
        while time.time() < deadline:
            time.sleep(30)
            chk = sbx.commands.run(
                "cat /tmp/bench.done 2>/dev/null; "
                "tail -1 /tmp/bench.log 2>/dev/null | head -c 200; "
                "pgrep -f bench.sh > /dev/null && echo RUNNING || echo STOPPED",
                timeout=120,
            )
            out = chk.stdout or ""
            if "done" in out or "STOPPED" in out:
                break
        raw = sbx.files.read("/home/user/result.json")
        result = json.loads(raw)
        numeric = all(isinstance(result.get(k), (int, float))
                      for k in ("start_cold", "start_stopped", "restart"))
        result["complete"] = numeric
        result["wall_seconds"] = round(time.time() - started, 1)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(result, indent=2))
        if numeric:
            log(f"done {tag}: cold={result.get('start_cold')}s "
                f"stopped={result.get('start_stopped')}s restart={result.get('restart')}s")
        else:
            missing = {k: result.get(k) for k in ("start_cold", "dash_cold", "start_stopped", "restart")
                       if not isinstance(result.get(k), (int, float))}
            log(f"partial {tag}: {missing}")
    except Exception as e:  # noqa: BLE001
        log(f"ERROR {tag}: {str(e)[:300]}")
    finally:
        if sbx:
            try:
                sbx.kill()
            except Exception:
                pass


def _json_part(stdout):
    """Extract the JSON object bench.sh echoes at the end."""
    start = stdout.find("{")
    end = stdout.rfind("}")
    return stdout[start:end + 1] if start != -1 and end != -1 else "{}"


def run_mode(mode, workers, presets, only_tags):
    templates = get_templates()
    missing = [f"c{c}-m{r}" for c in CPU_CONFIGS for r in RAM_CONFIGS
               if f"{TEMPLATE_PREFIX}-c{c}-m{r}" not in templates]
    if missing:
        log(f"missing templates: {missing} — run: python3 orchestrate.py build-templates")
        sys.exit(1)

    jobs = []
    for preset in presets:
        for cpu in CPU_CONFIGS:
            for ram in RAM_CONFIGS:
                tag = f"{preset}-c{cpu}-m{ram}"
                if only_tags and tag not in only_tags:
                    continue
                jobs.append((mode, preset, cpu, ram,
                             templates[f"{TEMPLATE_PREFIX}-c{cpu}-m{ram}"]))
    log(f"{len(jobs)} run(s), {workers} concurrent")

    with futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futs = [pool.submit(run_one, *job) for job in jobs]
        for f in futures.as_completed(futs):
            f.result()


# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("build-templates")
    run_p = sub.add_parser("run")
    run_p.add_argument("--mode", choices=["prebuilt", "build"], required=True)
    run_p.add_argument("--workers", type=int, default=32)
    run_p.add_argument("--presets", nargs="*", default=PRESETS)
    run_p.add_argument("--only", nargs="*", default=[],
                       help="limit to preset-c<cpu>-m<ram> tags (resumable runs)")
    args = ap.parse_args()

    if "E2B_API_KEY" not in os.environ:
        sys.exit("E2B_API_KEY must be set")

    if args.cmd == "build-templates":
        templates = build_templates()
        log(f"templates ready: {len(templates)}")
    else:
        run_mode(args.mode, args.workers, args.presets, set(args.only) or None)


if __name__ == "__main__":
    main()
