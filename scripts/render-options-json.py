#!/usr/bin/env python3
"""Translate config.env/app toggles into the JSON used by installapps-parallel.sh."""

import json
import sys
from pathlib import Path


DEFAULTS = {
    "FASTVM_APP_WINE": "false",
    "FASTVM_APP_CHROME": "false",
    "FASTVM_APP_XARCHIVER": "false",
    "FASTVM_APP_DISCORD": "false",
    "FASTVM_APP_STEAM": "false",
    "FASTVM_APP_MINECRAFT": "false",
    "FASTVM_PROG_JAVA8": "false",
    "FASTVM_PROG_JAVA17": "false",
    "FASTVM_PROG_VSCODIUM": "false",
    "FASTVM_APP_VLC": "false",
    "FASTVM_APP_LIBREOFFICE": "false",
    "FASTVM_APP_SYNAPTIC": "false",
    "FASTVM_APP_AQEMU": "false",
    "FASTVM_APP_TLAUNCHER": "false",
    "FASTVM_APP_FLATPAK": "false",
    "FASTVM_APP_HEROIC": "false",
    "FASTVM_APP_MODRINTH": "false",
    "FASTVM_AUDIO_ENABLED": "true",
    "FASTVM_CLIPBOARD_ENABLED": "true",
    "FASTVM_RECORDING_ENABLED": "true",
    "FASTVM_BACKUP_ENABLED": "true",
    "FASTVM_PRESET": "none",
    "FASTVM_DE": "XFCE4",
}


def parse_env_file(path: Path):
    values = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def is_truthy(value):
    return str(value).strip().lower() in {"1", "true", "yes", "on", "y"}


def map_desktop(value):
    mapping = {
        "XFCE4": "XFCE4 (Lightweight)",
        "KDE": "KDE Plasma (Heavy)",
        "GNOME": "GNOME 42 (Very Heavy)",
        "Cinnamon": "Cinnamon",
        "LXQT": "LXQT",
        "I3": "I3",
        "Budgie": "Budgie",
        "MATE": "MATE (Classic)",
        "LXDE": "LXDE (Ultra Lightweight)",
        "Fluxbox": "Fluxbox (Minimal WM)",
        "Unity": "Unity (Ubuntu Classic)",
        "UbuntuStudio": "Ubuntu Studio (KDE Flavor)",
        "ubuntu-studio": "Ubuntu Studio (KDE Flavor)",
        "Enlightenment": "Enlightenment (Eye Candy)",
        "IceWM": "IceWM (Very Lightweight)",
        "awesome": "awesome (Tiling)",
        "UKUI": "UKUI Desktop",
        "BSPWM": "BSPWM (Tiling)",
        "GNOME-Flashback": "GNOME Flashback (Classic)",
        "GNOME Flashback": "GNOME Flashback (Classic)",
        "Flashback": "GNOME Flashback (Classic)",
        "WMAKER": "Window Maker (Minimal)",
        "WindowMaker": "Window Maker (Minimal)",
        "Window Maker": "Window Maker (Minimal)",
        "FASTVM-OS": "FastVM OS",
        "fastvm-os": "FastVM OS",
    }
    return mapping.get(str(value), str(value))


def build_group(entries, env):
    selected = []
    for key, index in entries:
        if is_truthy(env.get(key, DEFAULTS.get(key, "false"))):
            selected.append(index)
    return selected


def main():
    config_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("config.env")
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("options.json")

    env = parse_env_file(config_path)
    for key, value in DEFAULTS.items():
        env.setdefault(key, value)

    data = {
        "defaultapps": build_group(
            [
                ("FASTVM_APP_WINE", 0),
                ("FASTVM_APP_CHROME", 1),
                ("FASTVM_APP_XARCHIVER", 2),
                ("FASTVM_APP_DISCORD", 3),
                ("FASTVM_APP_STEAM", 4),
                ("FASTVM_APP_MINECRAFT", 5),
            ],
            env,
        ),
        "programming": build_group(
            [
                ("FASTVM_PROG_JAVA8", 0),
                ("FASTVM_PROG_JAVA17", 1),
                ("FASTVM_PROG_VSCODIUM", 2),
            ],
            env,
        ),
        "apps": build_group(
            [
                ("FASTVM_APP_VLC", 0),
                ("FASTVM_APP_LIBREOFFICE", 1),
                ("FASTVM_APP_SYNAPTIC", 2),
                ("FASTVM_APP_AQEMU", 3),
                ("FASTVM_APP_TLAUNCHER", 4),
                ("FASTVM_APP_FLATPAK", 5),
                ("FASTVM_APP_HEROIC", 6),
                ("FASTVM_APP_MODRINTH", 7),
            ],
            env,
        ),
        "enablekvm": True,
        "DE": map_desktop(env.get("FASTVM_DE", "XFCE4")),
        "preset": env.get("FASTVM_PRESET", "none"),
        "audio": is_truthy(env.get("FASTVM_AUDIO_ENABLED", "true")),
        "clipboard": is_truthy(env.get("FASTVM_CLIPBOARD_ENABLED", "true")),
        "recording": is_truthy(env.get("FASTVM_RECORDING_ENABLED", "true")),
        "backup": is_truthy(env.get("FASTVM_BACKUP_ENABLED", "true")),
        "dashboard": True,
    }

    output_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
