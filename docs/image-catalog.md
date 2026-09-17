# FastVM Image Catalog

FastVM publishes 42 desktop/preset combinations and 4 single-app variants.
Tags follow `<desktop>-<preset>-latest` or `<name>-latest`; release tags add
`-vX.Y.Z`. The supported desktop values are `xfce4`, `kde`, `gnome`,
`cinnamon`, `lxqt`, `i3`, and `budgie`. Presets are `none`, `minimal`,
`gaming`, `development`, `office`, and `content-creation`.

| Category | Variants | Notes |
| --- | ---: | --- |
| Desktop + preset | 42 | Built from the workflow matrix |
| Single-app | 4 | browser, discord, vscode, terminal |

Exact package contents are defined by `presets/*.preset` and
`installable-apps/*.sh`; update this document when the workflow matrix changes.
