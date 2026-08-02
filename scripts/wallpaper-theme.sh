#!/usr/bin/env bash
# ~/.config/quickshell/scripts/wallpaper-theme.sh
# Called by hyprland when wallpaper changes. Runs matugen to regenerate
# ~/.config/quickshell/colors.json so the shell hot-reloads its theme.
# Usage: wallpaper-theme.sh <path-to-wallpaper>

WALLPAPER="$1"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "wallpaper-theme: no valid wallpaper path given" >&2
    exit 1
fi

matugen image "$WALLPAPER" -q --mode dark --prefer saturation 2>/dev/null

exit 0
