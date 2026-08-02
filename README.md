# MaterialUI Simple Taskbar (Quickshell)
A simple quickshell configuration that aims Android 16 UI like appearance.

> [!NOTE]
> Strictly speaking, this is a hyprland's only quickshell configuration (for now) so, do not expect it to work outside the environment, you may try, but I won't guarantee a fully functional bar.
>
> To add, I haven't implemented a settings GUI app yet, going to have it soon in the future.


## What you'll need (Dependencies)
1. Hyprland (obviously)
2. Quickshell
3. NetworkManager (or NetworkManager with iwd backend for some of y'all)
4. Hyprsunset (for night light)
5. Bluetooth daemon (optional)
6. Matugen (optional)
7. Papirus icon theme
8. Hyprshutdown
9. python-pillow
10. ~~Any notification daemon (swaync, dunst, mako, etc)~~

## What you need to do to get this shell working?
1. First, go to the preferred directory to clone this repository (i.e Downloads).
2. Then run `git clone https://github.com/ps2string/quickshell-materialui`
3. After that, create a new folder inside `~/.config` named `quickshell`
4. Move the contents inside the cloned directory inside the new folder
5. Run quickshell (either with `qs` or just `quickshell`)

## Automatic Color Apply (via Matugen)
- By default, it will use blue colors as it's main palette, and it will hot reload as long as `colors.json` exists in `~/.config/quickshell/`
- A template for matugen `colors.json` inside `~/.config/matugen/templates/colors.json`
```json
{
    "accent": "{{colors.primary.default.hex}}",
    "accentDim": "{{colors.primary_container.default.hex}}",
    "accentOnDim": "{{colors.on_primary_container.default.hex}}",
    "bgBase": "{{colors.background.default.hex}}",
    "bgSurface": "{{colors.surface.default.hex}}",
    "bgElevated": "{{colors.surface_container.default.hex}}",
    "bgHover": "{{colors.surface_variant.default.hex}}",
    "textPrimary": "{{colors.on_surface.default.hex}}",
    "textSecondary": "{{colors.on_surface_variant.default.hex}}",
    "danger": "{{colors.error.default.hex}}",
    "success": "{{colors.tertiary.default.hex}}",
    "outline": "{{colors.outline.default.hex}}"
}
```
- As for the `config.toml` inside `~/.config/matugen/`
```toml
[config]
# Any configuration you want to put here

[templates.quickshell]
input_path = "~/.config/matugen/templates/materialui_bar.json"
output_path = "~/.config/quickshell/colors.json"

```

## Additional Notes
- In order to open the start menu via keyboard keys (or via anything in that matter) I've also prepared quickshell native IPC calls that can be used in hyprland:

```terminal
target launcher
  function open(): void
  function toggle(): void
  function close(): void
```
- Where:
- `open` opens the launcher (`qs -p ~/.config/quickshell ipc call launcher open`)
- `toggle` opens/closes the launcher (`qs -p ~/.config/quickshell ipc call launcher toggle`)
- `close` closes the launcher (`qs -p ~/.config/quickshell ipc call launcher close`)

## Important notes:
- Make sure your wallpapers are saved inside `~/Pictures/Wallpapers` as that's the most reliable path I've tested to work best.
- You can change it by using `Open Folder` button, but I'm not guaranteeing it to work properly as of now.

## Previews
---
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/e4b1b38d-dd53-4839-8315-ff15482b3187" />

---
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/02bbcac4-fcf6-41e1-bd60-d4c7b189813e" />

