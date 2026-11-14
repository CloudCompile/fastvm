# FastVM Image Catalog

FastVM publishes 198 desktop/preset combinations and 4 single-app variants.
Tags follow `<desktop>-<preset>-latest` or `<name>-latest`; release tags add
`-vX.Y.Z`. The supported desktop values are `xfce4`, `kde`, `gnome`,
`cinnamon`, `lxqt`, `i3`, `budgie`, `mate`, `lxde`, `fluxbox`, `unity`,
`enlightenment`, `icewm`, `awesome`, `ukui`, `bspwm`, `herbstluftwm`, `jwm`,
`fvwm`, `gnome-flashback`, `wmaker`, `xmonad`, `sugar`, `dwm`, `ratpoison`,
`blackbox`, `pekwm`, `spectrwm`, `sawfish`, `openbox`, `afterstep`, `ctwm`,
and `twm`.
Presets are `none`, `minimal`, `gaming`, `development`, `office`, and
`content-creation`.

One FastVM-specific appliance flavor is published separately:
`fastvm-os-latest` (the Openbox/Tint2 FastVM appliance shell). FastVM desktop
environments are Ubuntu/KasmVNC-based desktop images, not independent Linux
distributions. The former distro-branded tags were identity/desktop overlays on
the same Ubuntu base and have been removed to avoid implying upstream OS support.
Choose `kde`, `xfce4`, `cinnamon`, `mate`, `gnome`, `ukui`, `unity`, or another
supported desktop in the regular desktop/preset matrix instead.

| Category | Variants | Notes |
| --- | ---: | --- |
| Desktop + preset | 198 | Built from the workflow matrix |
| Single-app | 4 | browser, discord, vscode, terminal |
| FastVM appliance | 1 | fastvm-os |

## Tags by category

Tags are immutable only when version-pinned (`<tag>-vX.Y.Z`); `latest` is a
moving tag updated by the image workflow on `main`.

| Category | Tag pattern | Published variants | Examples |
| --- | --- | ---: | --- |
| Desktop + preset | `<desktop>-<preset>-latest` | 198 | `xfce4-none-latest`, `kde-gaming-latest` |
| Single app | `<app>-latest` | 4 | `browser-latest`, `terminal-latest` |
| FastVM appliance | `fastvm-os-latest` | 1 | `fastvm-os-latest` |

There are no separate Kali, Parrot, NixOS, pearOS, Pop!_OS, Linux Mint, or
Ubuntu-flavor OS images in the supported matrix. To select KDE, for example,
use `kde-none-latest`; it is a FastVM image on the Ubuntu/KasmVNC base, not an
upstream Kubuntu image.

Exact package contents are defined by `presets/*.preset` and
`installable-apps/*.sh`; update this document when the workflow matrix changes.

## App bundles

Desktop images bake in a curated **app bundle** rather than only a browser. The
`none` preset uses the desktop default (`essentials` for full desktops, `browser`
for minimal WMs); other presets map to their matching bundle. See
[app-bundles.md](app-bundles.md).

## Single-app images

| Tag | App |
| --- | --- |
| `browser-latest` | Chrome |
| `discord-latest` | Discord (no desktop environment) — see [discord-vm.md](discord-vm.md) |
| `vscode-latest` | VSCodium |
| `terminal-latest` | terminal |
