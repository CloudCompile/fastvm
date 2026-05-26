#!/usr/bin/env python3
"""
FastVM Pterodactyl Launcher
Deploys FastVM on constrained Pterodactyl VPS with non-root execution.

Constraints:
  - 2 CPU, 3 GB RAM, ~15 GB storage
  - Non-root execution (runs as unprivileged user)
  - Deployed via docker-compose or podman-compose
  - Uses prebuilt images from ghcr.io

Configuration:
  - Set FASTVM_PRESET=hidencloud-free-vps in config.env
  - FASTVM_PORT defaults to 3000 (web desktop)
  - FASTVM_DASHBOARD_HOST_PORT defaults to 3001 (API dashboard)
"""

import os
import sys
import json
import subprocess
import time
import argparse
from pathlib import Path
from typing import Dict, Optional, List, Tuple


class FastVMPterodactylLauncher:
    """Manages FastVM deployment on Pterodactyl VPS."""

    def __init__(self, base_dir: str = "."):
        """Initialize launcher."""
        self.base_dir = Path(base_dir).resolve()
        self.config_file = self.base_dir / "config.env"
        self.docker_compose_file = self.base_dir / "docker-compose.yml"
        self.data_dir = self.base_dir / "data"
        self.backups_dir = self.base_dir / "backups"
        self.recordings_dir = self.base_dir / "recordings"
        self.logs_dir = self.base_dir / "logs"
        self.config: Dict[str, str] = {}
        self.runtime = self._detect_runtime()

    def log(self, level: str, msg: str) -> None:
        """Log a message with timestamp."""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {msg}", file=sys.stderr)

    def log_info(self, msg: str) -> None:
        """Log info level."""
        self.log("INFO", msg)

    def log_warn(self, msg: str) -> None:
        """Log warning level."""
        self.log("WARN", msg)

    def log_error(self, msg: str) -> None:
        """Log error level."""
        self.log("ERROR", msg)

    def log_step(self, msg: str) -> None:
        """Log a major step."""
        print(f"\n{'='*70}", file=sys.stderr)
        print(f">>> {msg}", file=sys.stderr)
        print(f"{'='*70}\n", file=sys.stderr)

    def run_cmd(
        self, cmd: List[str], check: bool = True, capture: bool = False
    ) -> Tuple[int, str]:
        """Run a shell command."""
        try:
            if capture:
                result = subprocess.run(
                    cmd, check=check, capture_output=True, text=True
                )
                return result.returncode, result.stdout.strip()
            else:
                result = subprocess.run(cmd, check=check)
                return result.returncode, ""
        except subprocess.CalledProcessError as e:
            if check:
                raise
            return e.returncode, ""
        except FileNotFoundError:
            self.log_error(f"Command not found: {cmd[0]}")
            return 127, ""

    def _detect_runtime(self) -> str:
        """Detect Docker or Podman."""
        rc_docker, _ = self.run_cmd(["docker", "--version"], check=False)
        if rc_docker == 0:
            return "docker"

        rc_podman, _ = self.run_cmd(["podman", "--version"], check=False)
        if rc_podman == 0:
            return "podman"

        self.log_warn("Neither docker nor podman found")
        return "docker"  # Default fallback

    def setup_directories(self) -> None:
        """Create required data directories."""
        self.log_step("Setting up directories")
        dirs = [self.data_dir, self.backups_dir, self.recordings_dir, self.logs_dir]
        for d in dirs:
            d.mkdir(parents=True, exist_ok=True)
            self.log_info(f"  ✓ {d.relative_to(self.base_dir)}")

    def load_config(self) -> None:
        """Load configuration from config.env file."""
        self.log_step("Loading configuration")
        if not self.config_file.exists():
            self.log_error(f"Config file not found: {self.config_file}")
            sys.exit(1)

        with open(self.config_file, "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    if "=" in line:
                        key, value = line.split("=", 1)
                        self.config[key.strip()] = value.strip()

        self.log_info(f"  Loaded {len(self.config)} config entries")

        # Log key settings
        preset = self.config.get("FASTVM_PRESET", "none")
        port = self.config.get("FASTVM_PORT", "3000")
        dashboard_port = self.config.get("FASTVM_DASHBOARD_HOST_PORT", "3001")
        de = self.config.get("FASTVM_DE", "XFCE4")
        cpu = self.config.get("FASTVM_CPU_LIMIT", "0")
        mem = self.config.get("FASTVM_MEMORY_LIMIT", "0")

        self.log_info(f"  Preset: {preset}")
        self.log_info(f"  Desktop: {de}")
        self.log_info(f"  CPU limit: {cpu}")
        self.log_info(f"  Memory limit: {mem}")
        self.log_info(f"  Web port: {port}")
        self.log_info(f"  Dashboard port: {dashboard_port}")

    def check_runtime(self) -> None:
        """Check if Docker/Podman is available."""
        self.log_step("Checking container runtime")
        rc, version = self.run_cmd([self.runtime, "--version"], capture=True)
        if rc == 0:
            self.log_info(f"  ✓ Using {self.runtime}: {version}")
        else:
            self.log_error(f"  ✗ {self.runtime} not available")
            self.log_info("  Attempting to install Docker...")
            self._install_docker()

    def _install_docker(self) -> None:
        """Attempt to install Docker (non-root friendly)."""
        self.log_info("  Checking for Docker installation script...")

        # Try apt-get (Debian/Ubuntu)
        rc, _ = self.run_cmd(["which", "apt-get"], check=False)
        if rc == 0:
            self.log_info("  Found apt-get, installing docker.io...")
            # For non-root, we'll attempt to install but note limitations
            cmds = [
                ["sudo", "apt-get", "update"],
                ["sudo", "apt-get", "install", "-y", "docker.io", "docker-compose"],
                [
                    "sudo",
                    "usermod",
                    "-aG",
                    "docker",
                    os.environ.get("USER", "pterodactyl"),
                ],
            ]
            for cmd in cmds:
                rc, _ = self.run_cmd(cmd, check=False)
                if rc != 0:
                    self.log_warn(f"  Command failed (may need manual setup): {' '.join(cmd)}")
        else:
            self.log_error(
                "  Could not install Docker. Please install manually or use Podman."
            )
            self.log_info(
                "  See: https://docs.docker.com/engine/install/ or https://podman.io/"
            )

    def start_container(self, detach: bool = True) -> None:
        """Start the FastVM container."""
        self.log_step("Starting FastVM container")

        # Use docker-compose or podman-compose
        compose_cmd = (
            f"{self.runtime}-compose" if self.runtime == "podman" else "docker-compose"
        )

        # Check if docker-compose exists, fall back to docker compose
        rc, _ = self.run_cmd([compose_cmd, "--version"], check=False)
        if rc != 0:
            compose_cmd = f"{self.runtime} compose"

        # Export environment variables for docker-compose
        env = os.environ.copy()
        for key, value in self.config.items():
            if key.startswith("FASTVM_") or key in ["BUILD_DATE", "VERSION"]:
                env[key] = value

        try:
            cmd = [compose_cmd, "up", "-d"] if detach else [compose_cmd, "up"]
            cmd = cmd[0].split() + cmd[1:] if " " in compose_cmd else cmd
            self.log_info(f"  Running: {' '.join(cmd)}")
            result = subprocess.run(
                cmd, cwd=self.base_dir, env=env, check=True
            )
            self.log_info("  ✓ Container started successfully")
        except subprocess.CalledProcessError as e:
            self.log_error(f"  ✗ Failed to start container: {e}")
            sys.exit(1)

    def status(self) -> None:
        """Show container status."""
        self.log_step("FastVM Container Status")

        ps_cmd = f"{self.runtime} ps"
        ps_cmd = ps_cmd.split()
        rc, output = self.run_cmd(ps_cmd, check=False, capture=True)

        if rc == 0:
            lines = output.split("\n")
            found = False
            for line in lines:
                if "fastvm" in line.lower() or "FastVM" in line:
                    print(line)
                    found = True

            if found:
                self.log_info("  ✓ FastVM container is running")
            else:
                self.log_warn("  FastVM container not found")
        else:
            self.log_error(f"  Failed to get container status")

    def stop_container(self) -> None:
        """Stop the FastVM container."""
        self.log_step("Stopping FastVM container")
        try:
            compose_cmd = (
                f"{self.runtime}-compose"
                if self.runtime == "podman"
                else "docker-compose"
            )
            rc, _ = self.run_cmd([compose_cmd, "--version"], check=False)
            if rc != 0:
                compose_cmd = f"{self.runtime} compose"

            cmd = [compose_cmd, "down"]
            cmd = cmd[0].split() + cmd[1:] if " " in compose_cmd else cmd
            self.run_cmd(cmd, cwd=self.base_dir)
            self.log_info("  ✓ Container stopped")
        except Exception as e:
            self.log_error(f"  Failed to stop container: {e}")

    def logs(self, lines: int = 50) -> None:
        """Show container logs."""
        self.log_step(f"FastVM Logs (last {lines} lines)")
        try:
            compose_cmd = (
                f"{self.runtime}-compose"
                if self.runtime == "podman"
                else "docker-compose"
            )
            rc, _ = self.run_cmd([compose_cmd, "--version"], check=False)
            if rc != 0:
                compose_cmd = f"{self.runtime} compose"

            cmd = [compose_cmd, "logs", "--tail", str(lines)]
            cmd = cmd[0].split() + cmd[1:] if " " in compose_cmd else cmd
            self.run_cmd(cmd, check=False, cwd=self.base_dir)
        except Exception as e:
            self.log_error(f"  Failed to get logs: {e}")

    def print_access_info(self) -> None:
        """Print access information."""
        print("\n" + "=" * 70, file=sys.stderr)
        print("FastVM is starting up. Access points:", file=sys.stderr)
        print("=" * 70, file=sys.stderr)

        port = self.config.get("FASTVM_PORT", "3000")
        dashboard_port = self.config.get("FASTVM_DASHBOARD_HOST_PORT", "3001")
        hostname = os.environ.get("HOSTNAME", "localhost")

        print(f"\n  🖥️  Web Desktop (KasmVNC):", file=sys.stderr)
        print(f"     http://{hostname}:{port}", file=sys.stderr)
        print(f"     Default: No password required initially", file=sys.stderr)

        print(f"\n  📊 API Dashboard:", file=sys.stderr)
        print(f"     http://{hostname}:{dashboard_port}", file=sys.stderr)
        print(f"     Requires token (see container logs for initial token)", file=sys.stderr)

        print("\n  ⏱️  Initial startup: 30-60 seconds", file=sys.stderr)
        print("  📝 Logs: app.py logs", file=sys.stderr)
        print("\n" + "=" * 70 + "\n", file=sys.stderr)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="FastVM Pterodactyl Launcher")
    parser.add_argument(
        "command",
        choices=["start", "stop", "status", "logs", "install"],
        help="Command to run",
    )
    parser.add_argument("--lines", type=int, default=50, help="Number of log lines to show")
    parser.add_argument("--dir", default=".", help="FastVM base directory")

    args = parser.parse_args()

    launcher = FastVMPterodactylLauncher(args.dir)

    try:
        if args.command == "start":
            launcher.setup_directories()
            launcher.load_config()
            launcher.check_runtime()
            launcher.start_container(detach=True)
            time.sleep(2)
            launcher.status()
            launcher.print_access_info()

        elif args.command == "stop":
            launcher.stop_container()

        elif args.command == "status":
            launcher.status()

        elif args.command == "logs":
            launcher.logs(args.lines)

        elif args.command == "install":
            launcher.log_step("Installing dependencies")
            launcher.check_runtime()

    except KeyboardInterrupt:
        launcher.log_warn("Interrupted by user")
        sys.exit(130)
    except Exception as e:
        launcher.log_error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
