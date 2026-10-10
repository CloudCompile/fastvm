# FastVM Image Catalog

FastVM publishes 126 desktop/preset combinations and 4 single-app variants.
Tags follow `<desktop>-<preset>-latest` or `<name>-latest`; release tags add
`-vX.Y.Z`. The supported desktop values are `xfce4`, `kde`, `gnome`,
`cinnamon`, `lxqt`, `i3`, `budgie`, `mate`, `lxde`, `fluxbox`, `unity`,
`enlightenment`, `icewm`, `awesome`, `ukui`, `bspwm`, `herbstluftwm`, `jwm`,
`fvwm`, `gnome-flashback`, and `wmaker`.
Presets are `none`, `minimal`, `gaming`, `development`, `office`, and
`content-creation`.

Seven additive distro-flavor images are published separately and do not replace
any desktop/preset tag: `fastvm-os-latest` (Openbox/Tint2 appliance shell),
`ubuntu-studio-latest` (KDE Plasma with the Ubuntu Studio 22.04 identity layer),
`ubuntu-kylin-latest` (UKUI with the Ubuntu Kylin 22.04 identity layer),
`ubuntu-budgie-latest` (Budgie with the Ubuntu Budgie 22.04 identity layer),
`ubuntu-edubuntu-latest` (GNOME with the Ubuntu Edubuntu 22.04 identity layer),
`xubuntu-latest` (XFCE with the Xubuntu 22.04 identity layer), and
`lubuntu-latest` (LXQt with the Lubuntu 22.04 identity layer).

| Category | Variants | Notes |
| --- | ---: | --- |
| Desktop + preset | 126 | Built from the workflow matrix |
| Single-app | 4 | browser, discord, vscode, terminal |
| Distro flavor | 7 | fastvm-os, ubuntu-studio, ubuntu-kylin, ubuntu-budgie, ubuntu-edubuntu, xubuntu, lubuntu |

Exact package contents are defined by `presets/*.preset` and
`installable-apps/*.sh`; update this document when the workflow matrix changes.
