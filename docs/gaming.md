# Gaming guidance

FastVM is designed for Linux desktop sessions inside a browser. It is not a Windows VM project, and Windows support is intentionally not offered because browser-streamed Windows desktops are too slow and resource-heavy for the typical Codespaces or low-memory environment.

## Included gaming defaults

The gaming preset includes:

- Steam + Proton
- Wine
- Flatpak support
- Heroic Games Launcher (Epic-style game access)
- Modrinth App
- Minecraft and TLauncher options
- controller support and DXVK hooks

## Common setup

Use the gaming preset in your config:

```bash
FASTVM_PRESET=gaming
```

Then review the app toggles if you want to fine-tune the image:

```bash
FASTVM_APP_STEAM=true
FASTVM_APP_WINE=true
FASTVM_APP_FLATPAK=true
FASTVM_APP_HEROIC=true
FASTVM_APP_MODRINTH=true
```

## Notes

- Flatpak is the easiest path for launcher-based installations.
- Steam is included by default in the gaming preset.
- If you are using a host with hardware acceleration available, you can optionally map GPU devices for better gaming performance.
