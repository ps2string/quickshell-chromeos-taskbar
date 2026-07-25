# ChromeOS Taskbar (Quickshell)
A simple quickshell configuration that looks like chromeOS panel.

> [!NOTE]
> Strictly speaking, this is a hyprland's only quickshell configuration (for now) so, do not expect it to work outside the environment, you may try, but I won't guarantee a fully functional bar.
> I haven't implemented a settings GUI app yet, going to have it soon in the future.


## What you'll need (Dependencies)
1. Hyprland (obviously)
2. Quickshell
3. NetworkManager (or NetworkManager with iwd backend for some of y'all)
4. Hyprsunset (for night light)
5. Bluetooth daemon (optional)
6. Matugen (optional)
7. Papirus icon theme

## What you need to do to get this shell working?
1. First, go to the prefered directory to clone this repository (i.e Downloads.
2. Then run `git clone https://github.com/ps2string/quickshell-chromeos-taskbar`
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
input_path = "~/.config/matugen/templates/qschromeos-bar.json"
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

## Known Bugs:
- Clicking on running apps doesn't open the specific app
- Icons on running apps doesn't show what app is it (therefore unable to pin it without causing another bug)
- Pinning on running apps (that uses its title as the icon) are discouraged cause you can't remove it once you've pinned it (unless you just delete its entry inside `~/.config/quickshell/pins.json`)

## Previews
---
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/225a077c-d38f-4365-b082-7c09d428db9e" />

---
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/56917015-2a6a-4640-a5af-495b1fe8617b" />

- When wallpaper changed:
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/78652dbb-18ad-40f9-8dc2-5ca4a15ad933" />
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/9fbbb5da-3e96-45d1-839c-a51905210403" />
