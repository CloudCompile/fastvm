import json
import os
from textual.app import App, ComposeResult
from textual.screen import Screen
from textual.containers import Horizontal, Vertical, ScrollableContainer
from textual.widgets import (
    Footer, Header, SelectionList, Label, Button,
    Markdown, Select, Static, Switch, Rule,
)

# ---------------------------------------------------------------------------
# JSON output
# ---------------------------------------------------------------------------

def savejson(data):
    with open('options.json', 'w') as f:
        json.dump(data, f)

# ---------------------------------------------------------------------------
# Copy chosen preset values into config.env (host-side)
# ---------------------------------------------------------------------------

PRESET_DIR = os.path.join(os.path.dirname(__file__), 'presets')

def apply_preset_to_env(preset_name: str):
    """Merge preset key=value pairs into config.env."""
    if not preset_name or preset_name == 'none':
        return
    preset_file = os.path.join(PRESET_DIR, f'{preset_name}.preset')
    if not os.path.exists(preset_file):
        return
    overrides = {}
    with open(preset_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=', 1)
            overrides[k.strip()] = v.strip()

    env_file = os.path.join(os.path.dirname(__file__), 'config.env')
    if not os.path.exists(env_file):
        return
    with open(env_file) as f:
        lines = f.readlines()
    new_lines = []
    applied = set()
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('#') or '=' not in stripped:
            new_lines.append(line)
            continue
        key = stripped.split('=', 1)[0].strip()
        if key in overrides:
            new_lines.append(f'{key}={overrides[key]}\n')
            applied.add(key)
        else:
            new_lines.append(line)
    # Append any preset keys that weren't already in config.env
    for k, v in overrides.items():
        if k not in applied:
            new_lines.append(f'{k}={v}\n')
    with open(env_file, 'w') as f:
        f.writelines(new_lines)

# ---------------------------------------------------------------------------
# UI strings
# ---------------------------------------------------------------------------

Head = """
# FastVM

> Browser-based Linux desktop, powered by KasmVNC + Docker.

✦ Runs entirely in your browser — no client software needed
✦ Windows app support via Wine
✦ Audio, clipboard, and screen recording built-in
✦ Snapshots & automated backups
✦ Management dashboard on port 3001
✦ Gaming, development, office and content-creation presets
"""

InstallHead = """
# FastVM — Configure your installation
"""

DE_LINES = [
    "XFCE4 (Lightweight)",
    "Budgie (Modern)",
    "KDE Plasma (Heavy)",
    "I3 (Very Lightweight)",
    "GNOME 42 (Very Heavy)",
    "Cinnamon",
    "LXQT",
]

PRESET_LINES = [
    ("None — manual selection", "none"),
    ("Minimal  · terminal + browser", "minimal"),
    ("Gaming   · Wine + Steam + DXVK", "gaming"),
    ("Development · VSCodium + Java + Git", "development"),
    ("Office   · LibreOffice + Firefox", "office"),
    ("Content Creation · GIMP + Audacity + OBS", "content-creation"),
]

# ---------------------------------------------------------------------------
# Screens
# ---------------------------------------------------------------------------

class InstallScreen(Screen):
    CSS_PATH = "installer.tcss"

    def compose(self) -> ComposeResult:
        yield Header()
        yield Markdown(InstallHead)

        yield Label("Preset  (overrides individual selections below)")
        yield Select(
            options=PRESET_LINES,
            value="none",
            id="preset",
        )
        yield Rule()

        yield Horizontal(
            Vertical(
                Label("Default Apps"),
                SelectionList[int](
                    ("Wine",      0, True),
                    ("Chrome",    1, True),
                    ("Xarchiver", 2, False),
                    ("Discord",   3, False),
                    ("Steam",     4, False),
                    ("Minecraft", 5, False),
                    id="defaultapps",
                ),
            ),
            Vertical(
                Label("Programming"),
                SelectionList[int](
                    ("OpenJDK 8 (jre)",  0),
                    ("OpenJDK 17 (jre)", 1),
                    ("VSCodium",         2),
                    id="programming",
                ),
            ),
            Vertical(
                Label("Apps"),
                SelectionList[int](
                    ("VLC",         0),
                    ("LibreOffice", 1),
                    ("Synaptic",    2),
                    ("AQemu (VMs)", 3),
                    ("TLauncher",   4),
                    id="apps",
                ),
            ),
        )

        yield Rule()
        yield Vertical(
            Horizontal(
                Label("\nDesktop Environment :"),
                Select(
                    id="de",
                    value="XFCE4 (Lightweight)",
                    options=((line, line) for line in DE_LINES),
                ),
            ),
        )

        yield Rule()
        yield Label("Features")
        yield Horizontal(
            Vertical(Label("Audio"),     Switch(value=True,  id="sw-audio")),
            Vertical(Label("Clipboard"), Switch(value=True,  id="sw-clipboard")),
            Vertical(Label("Recording"), Switch(value=True,  id="sw-recording")),
            Vertical(Label("Backups"),   Switch(value=True,  id="sw-backup")),
            Vertical(Label("Dashboard"), Switch(value=True,  id="sw-dashboard")),
        )

        yield Horizontal(
            Button.error("Back",         id="back"),
            Button.warning("Install NOW", id="in"),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "back":
            app.pop_screen()
            return
        if event.button.id == "in":
            preset = self.query_one("#preset").value
            # Apply preset to config.env first.
            apply_preset_to_env(preset)
            data = {
                "defaultapps":        self.query_one("#defaultapps").selected,
                "programming":        self.query_one("#programming").selected,
                "apps":               self.query_one("#apps").selected,
                "enablekvm":          True,
                "DE":                 self.query_one("#de").value,
                "preset":             preset,
                "audio":              self.query_one("#sw-audio").value,
                "clipboard":          self.query_one("#sw-clipboard").value,
                "recording":          self.query_one("#sw-recording").value,
                "backup":             self.query_one("#sw-backup").value,
                "dashboard":          self.query_one("#sw-dashboard").value,
            }
            savejson(data)
            app.exit()


class InstallApp(App):
    CSS_PATH = "installer.tcss"

    def compose(self) -> ComposeResult:
        yield Header()
        yield Markdown(Head)
        yield Vertical(
            Button.success("Configure & Install", id="install"),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "install":
            self.push_screen(InstallScreen())


if __name__ == "__main__":
    app = InstallApp()
    app.run()
