# FastVM Image Catalog

FastVM publishes 66 desktop/preset combinations and 4 single-app variants.
Tags follow `<desktop>-<preset>-latest` or `<name>-latest`; release tags add
`-vX.Y.Z`. The supported desktop values are `xfce4`, `kde`, `gnome`,
`cinnamon`, `lxqt`, `i3`, `budgie`, `mate`, `lxde`, `fluxbox`, and `unity`.
Presets are `none`, `minimal`, `gaming`, `development`, `office`, and
`content-creation`.

Two additive distro-flavor images are published separately and do not replace
any desktop/preset tag: `fastvm-os-latest` (Openbox/Tint2 appliance shell) and
`ubuntu-studio-latest` (KDE Plasma with the Ubuntu Studio 22.04 identity layer).

| Category | Variants | Notes |
| --- | ---: | --- |
| Desktop + preset | 66 | Built from the workflow matrix |
| Single-app | 4 | browser, discord, vscode, terminal |
| Distro flavor | 2 | fastvm-os, ubuntu-studio |

Exact package contents are defined by `presets/*.preset` and
`installable-apps/*.sh`; update this document when the workflow matrix changes.
