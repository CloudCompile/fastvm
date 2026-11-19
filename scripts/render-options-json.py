#!/usr/bin/env python3
"""Translate config.env / build args into the JSON used by installapps-parallel.sh.

App selection is bundle-driven: each desktop and each preset has a default app
bundle (a curated set of apps), and individual ``FASTVM_APP_*`` / ``FASTVM_PROG_*``
toggles add to it. This is what makes a desktop image ship a useful app set
instead of only a browser.

Resolution order for the bundle (first non-empty wins):

1. ``FASTVM_APP_BUNDLE`` (config file, ``--bundle``, or the environment)
2. the preset's bundle (see ``PRESET_BUNDLE``), when a preset other than ``none``
   is selected
3. the desktop's default bundle (see ``DESKTOP_BUNDLE``)

Usage::

    render-options-json.py [config.env] [options.json] [--bundle NAME] [--desktop DE]

Environment variables (``FASTVM_APP_*``, ``FASTVM_PROG_*``, ``FASTVM_APP_BUNDLE``,
``FASTVM_DE``) override the config file, so the Docker build can drive the whole
manifest from ``ARG``/``ENV``.
"""

import argparse
import json
import os
import sys
from pathlib import Path

# App key -> (group, index) in options.json.
APP_MANIFEST = {
    "wine": ("defaultapps", 0),
    "chrome": ("defaultapps", 1),
    "xarchiver": ("defaultapps", 2),
    "discord": ("defaultapps", 3),
    "steam": ("defaultapps", 4),
    "minecraft": ("defaultapps", 5),
    "java8": ("programming", 0),
    "java17": ("programming", 1),
    "vscodium": ("programming", 2),
    "vlc": ("apps", 0),
    "libreoffice": ("apps", 1),
    "synaptic": ("apps", 2),
    "aqemu": ("apps", 3),
    "tlauncher": ("apps", 4),
    "flatpak": ("apps", 5),
    "heroic": ("apps", 6),
    "modrinth": ("apps", 7),
}

# Curated bundles. "essentials" is the desktop default; the rest map to a preset
# or an explicit FASTVM_APP_BUNDLE choice.
BUNDLE_APPS = {
    "none": [],
    "browser": ["chrome"],
    "essentials": ["chrome", "xarchiver", "vlc"],
    "communication": ["chrome", "discord"],
    "gaming": [
        "wine", "steam", "heroic", "tlauncher", "modrinth",
        "minecraft", "flatpak", "discord", "chrome", "java17",
    ],
    "development": ["vscodium", "chrome", "java17", "flatpak"],
    "office": ["libreoffice", "chrome", "xarchiver"],
    "content-creation": ["chrome", "vlc", "flatpak", "discord"],
}

VALID_BUNDLES = tuple(BUNDLE_APPS)

# Preset -> bundle. "none" falls through to the desktop default.
PRESET_BUNDLE = {
    "minimal": "browser",
    "gaming": "gaming",
    "development": "development",
    "office": "office",
    "content-creation": "content-creation",
}

# Desktops that ship almost nothing by nature get the bare browser bundle; every
# other desktop gets the full essentials set so images are not empty.
LIGHT_DESKTOPS = {
    "I3", "DWM", "dwm", "Ratpoison", "RATPOISON", "ratpoison", "BSPWM",
    "Herbstluftwm", "herbstluftwm", "HLWM", "Spectrwm", "SPECTRWM", "spectrwm",
    "awesome", "XMonad", "XMONAD", "xmonad", "Fluxbox", "Blackbox", "BLACKBOX",
    "blackbox", "JWM", "Jwm", "jwm", "FVWM", "Fvwm", "fvwm", "FVWM2",
    "CTWM", "ctwm", "TWM", "twm", "openbox", "Openbox", "OPENBOX", "PekWM",
    "pekwm", "PEKWM", "Sawfish", "SAWFISH", "sawfish", "AfterStep", "AFTERSTEP",
    "afterstep", "WMAKER", "WindowMaker", "Window Maker", "IceWM", "LXDE",
}

DEFAULTS = {
    "FASTVM_DE": "XFCE4",
    "FASTVM_PRESET": "none",
    "FASTVM_APP_BUNDLE": "",
    "FASTVM_SINGLEAPP_SCRIPT": "",
    "FASTVM_AUDIO_ENABLED": "true",
    "FASTVM_CLIPBOARD_ENABLED": "true",
    "FASTVM_RECORDING_ENABLED": "true",
    "FASTVM_BACKUP_ENABLED": "true",
}


def env_var_for(app_key: str) -> str:
    if app_key in {"java8", "java17", "vscodium"}:
        return "FASTVM_PROG_" + app_key.upper()
    return "FASTVM_APP_" + app_key.upper()


def parse_env_file(path: Path):
    values = {}
    if not path or not path.exists():
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
        "Enlightenment": "Enlightenment (Eye Candy)",
        "IceWM": "IceWM (Very Lightweight)",
        "awesome": "awesome (Tiling)",
        "UKUI": "UKUI Desktop",
        "BSPWM": "BSPWM (Tiling)",
        "Herbstluftwm": "herbstluftwm (Tiling)",
        "herbstluftwm": "herbstluftwm (Tiling)",
        "HLWM": "herbstluftwm (Tiling)",
        "JWM": "JWM (Ultra Light)",
        "Jwm": "JWM (Ultra Light)",
        "jwm": "JWM (Ultra Light)",
        "FVWM": "FVWM (Classic)",
        "Fvwm": "FVWM (Classic)",
        "fvwm": "FVWM (Classic)",
        "FVWM2": "FVWM (Classic)",
        "GNOME-Flashback": "GNOME Flashback (Classic)",
        "GNOME Flashback": "GNOME Flashback (Classic)",
        "Flashback": "GNOME Flashback (Classic)",
        "WMAKER": "Window Maker (Minimal)",
        "WindowMaker": "Window Maker (Minimal)",
        "Window Maker": "Window Maker (Minimal)",
        "dwm": "dwm (Tiling)",
        "DWM": "dwm (Tiling)",
        "ratpoison": "Ratpoison (Tiling)",
        "Ratpoison": "Ratpoison (Tiling)",
        "RATPOISON": "Ratpoison (Tiling)",
        "blackbox": "Blackbox (Minimal WM)",
        "Blackbox": "Blackbox (Minimal WM)",
        "BLACKBOX": "Blackbox (Minimal WM)",
        "pekwm": "PekWM (Lightweight)",
        "PekWM": "PekWM (Lightweight)",
        "PEKWM": "PekWM (Lightweight)",
        "spectrwm": "spectrwm (Tiling)",
        "Spectrwm": "spectrwm (Tiling)",
        "SPECTRWM": "spectrwm (Tiling)",
        "sawfish": "Sawfish (Scriptable)",
        "Sawfish": "Sawfish (Scriptable)",
        "SAWFISH": "Sawfish (Scriptable)",
        "FASTVM-OS": "FastVM OS",
        "fastvm-os": "FastVM OS",
    }
    return mapping.get(str(value), str(value))


def desktop_default_bundle(desktop: str) -> str:
    return "browser" if str(desktop).lower() in {d.lower() for d in LIGHT_DESKTOPS} else "essentials"


def resolve_bundle(env, explicit_bundle=None, desktop=None):
    # Single-app images install exactly one app via FASTVM_SINGLEAPP_SCRIPT, so
    # they must never pick up a bundle.
    if str(env.get("FASTVM_SINGLEAPP_SCRIPT") or "").strip():
        return "none"

    # 1. Explicit bundle (CLI, config, or env).
    bundle = (explicit_bundle or env.get("FASTVM_APP_BUNDLE") or "").strip().lower()
    if bundle and bundle != "none":
        return bundle if bundle in BUNDLE_APPS else "essentials"

    # 2. Preset bundle.
    preset = (env.get("FASTVM_PRESET") or "none").strip()
    if preset != "none":
        mapped = PRESET_BUNDLE.get(preset)
        if mapped:
            return mapped

    # 3. Desktop default.
    return desktop_default_bundle(desktop or env.get("FASTVM_DE", "XFCE4"))


def build_manifest(env, bundle):
    selected = set(BUNDLE_APPS.get(bundle, []))
    # Individual toggles add to the bundle (true wins; false cannot subtract).
    for app_key in APP_MANIFEST:
        value = env.get(env_var_for(app_key))
        if value is not None and is_truthy(value):
            selected.add(app_key)

    groups = {"defaultapps": [], "programming": [], "apps": []}
    for app_key, (group, index) in APP_MANIFEST.items():
        if app_key in selected:
            groups[group].append(index)
    for group in groups:
        groups[group].sort()
    return groups


def main(argv=None):
    parser = argparse.ArgumentParser(description="Render options.json from config.env")
    parser.add_argument("config", nargs="?", default="config.env")
    parser.add_argument("output", nargs="?", default="options.json")
    parser.add_argument("--bundle", default=None, help="App bundle name (overrides preset/desktop default)")
    parser.add_argument("--desktop", default=None, help="Desktop id (overrides config)")
    parser.add_argument("--preset", default=None, help="Preset name (overrides config)")
    args = parser.parse_args(argv)

    env = parse_env_file(Path(args.config))
    for key, value in DEFAULTS.items():
        env.setdefault(key, value)
    # Environment overrides config file (lets the Docker build drive it).
    for key in list(DEFAULTS) + [env_var_for(a) for a in APP_MANIFEST]:
        if key in os.environ:
            env[key] = os.environ[key]
    if args.desktop:
        env["FASTVM_DE"] = args.desktop
    if args.preset:
        env["FASTVM_PRESET"] = args.preset
    if args.bundle:
        env["FASTVM_APP_BUNDLE"] = args.bundle

    bundle = resolve_bundle(env, explicit_bundle=args.bundle, desktop=env.get("FASTVM_DE"))
    groups = build_manifest(env, bundle)

    data = {
        "defaultapps": groups["defaultapps"],
        "programming": groups["programming"],
        "apps": groups["apps"],
        "enablekvm": True,
        "DE": map_desktop(env.get("FASTVM_DE", "XFCE4")),
        "preset": env.get("FASTVM_PRESET", "none"),
        "bundle": bundle,
        "audio": is_truthy(env.get("FASTVM_AUDIO_ENABLED", "true")),
        "clipboard": is_truthy(env.get("FASTVM_CLIPBOARD_ENABLED", "true")),
        "recording": is_truthy(env.get("FASTVM_RECORDING_ENABLED", "true")),
        "backup": is_truthy(env.get("FASTVM_BACKUP_ENABLED", "true")),
        "dashboard": True,
    }

    Path(args.output).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
