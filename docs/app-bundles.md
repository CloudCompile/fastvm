# FastVM app bundles

Every desktop image bakes in a **curated set of apps** called a *bundle*. This
exists because a bare desktop (for example XFCE4) otherwise ships only a browser,
which makes the image feel empty.

## How the bundle is chosen

Precedence, highest first:

1. `FASTVM_APP_BUNDLE` — an explicit choice (config file, build arg, or environment)
2. the **preset** bundle, when `FASTVM_PRESET` is not `none`
3. the **desktop** default

Individual `FASTVM_APP_*` / `FASTVM_PROG_*` toggles are **additive** on top of the
bundle: setting one to `true` adds that app. A toggle set to `false` does not
remove an app the bundle already includes.

Single-app images (`FASTVM_SINGLEAPP_SCRIPT`, e.g. `discord-latest`) always
resolve to the `none` bundle — they install exactly one app and nothing else.

## Bundles

| Bundle | Apps |
| --- | --- |
| `none` | none |
| `browser` | Chrome |
| `essentials` | Chrome, Xarchiver, VLC |
| `communication` | Chrome, Discord |
| `gaming` | Wine, Steam, Heroic, TLauncher, Modrinth, Minecraft, Flatpak, Discord, Chrome, Java 17 |
| `development` | VSCodium, Chrome, Java 17, Flatpak |
| `office` | LibreOffice, Chrome, Xarchiver |
| `content-creation` | Chrome, VLC, Flatpak, Discord |

## Desktop defaults

Full desktop environments default to `essentials`, so XFCE4, KDE, GNOME, MATE,
Cinnamon and friends ship Chrome + Xarchiver + VLC out of the box.

Minimal window managers and tiling WMs (`i3`, `dwm`, `bspwm`, `awesome`,
`fluxbox`, `blackbox`, `jwm`, `fvwm`, `openbox`, `pekwm`, `spectrwm`, `sawfish`,
`afterstep`, `ctwm`, `twm`, `herbstluftwm`, `ratpoison`, `IceWM`, `LXDE`, …)
default to `browser`, since they are chosen for minimalism.

## Preset mapping

| Preset | Bundle |
| --- | --- |
| `none` | desktop default |
| `minimal` | `browser` |
| `gaming` | `gaming` |
| `development` | `development` |
| `office` | `office` |
| `content-creation` | `content-creation` |

## Choosing a bundle

### In `config.env`

```bash
FASTVM_APP_BUNDLE=communication
```

### At build time

```bash
docker build \
  --build-arg FASTVM_DE=KDE \
  --build-arg FASTVM_APP_BUNDLE=development \
  -t fastvm-kde-dev .
```

### Adding a single app on top

```bash
docker build \
  --build-arg FASTVM_DE=XFCE4 \
  --build-arg FASTVM_APP_BUNDLE=essentials \
  --build-arg FASTVM_APP_DISCORD=true \
  -t fastvm-xfce-discord .
```

## How it works

`scripts/render-options-json.py` resolves the bundle and writes `options.json`,
which `installapps-parallel.sh` reads to build the install queue. The Dockerfile
generates `options.json` during the build (Layer 4) from the `ARG`/`ENV` values,
so the selected desktop, preset and bundle actually reach the installer.
