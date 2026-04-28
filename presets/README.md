# FastVM Presets

A preset is a curated bundle of `FASTVM_*` config values plus optional
post-install hooks. Selecting a preset overlays its values on top of your
`config.env`; you can still tweak anything after the fact.

Activate a preset by setting:

```
FASTVM_PRESET=gaming
```

in `config.env`, then re-running `./fastvm-install.sh`.

## Available presets

| Name              | Best for                                  |
| ----------------- | ----------------------------------------- |
| `minimal`         | Maximum performance, terminal + browser   |
| `gaming`          | Wine + Steam + controllers + DXVK         |
| `development`     | VSCodium + Java + Docker tools            |
| `office`          | LibreOffice + Firefox + productivity      |
| `content-creation`| GIMP + Audacity + screen recording        |

## File format

Presets are plain `KEY=value` files (sourced as bash). Lines beginning with
`#` are comments. Anything not in `FASTVM_*` namespace is ignored.
