#!/usr/bin/env bash
# Apply a wallpaper and regenerate matugen colors for Hyprland and waybar,
# then reload them. Managed by fedup.
#
# Usage:
#   matugen-apply <image>   set wallpaper + regenerate colors + reload
#   matugen-apply           regenerate colors from the current wallpaper + reload
#
# This is wired into pibble's wallCommand (see seed-settings.sh) so picking a
# wallpaper in the pibble launcher themes the whole desktop.
set -euo pipefail

config="$HOME/.config/matugen/config.toml"
cache="$HOME/.cache/matugen"

# Resolve the wallpaper: explicit arg, else the one pibble last applied, else
# a random pick from the pika collection (fresh install before any pick).
wall="${1:-}"
if [ -z "$wall" ]; then
    shell_id=$(printf '%s' "$HOME/.config/pibble/shell.qml" | md5sum | cut -d' ' -f1)
    wall=$(jq -r '.currentWallpaper // empty' \
        "$HOME/.local/state/quickshell/by-shell/$shell_id/settings.json" 2>/dev/null || true)
fi
if [ -z "$wall" ] || [ ! -f "$wall" ]; then
    wall=$(find "$HOME/Pictures/Wallpapers/pika" -maxdepth 1 -type f 2>/dev/null | shuf -n 1)
fi
[ -n "$wall" ] && [ -f "$wall" ] || { echo "matugen-apply: no wallpaper found" >&2; exit 1; }

# 1. Set the wallpaper on every monitor via hyprpaper (kept as the wallpaper
#    manager). pibble's own wallCommand does this too, but running it here
#    makes `matugen-apply` usable standalone.
if command -v hyprctl >/dev/null 2>&1; then
    for m in $(hyprctl monitors -j | jq -r '.[].name'); do
        hyprctl hyprpaper wallpaper "$m,$wall" >/dev/null
    done
fi

# 2. Regenerate the color files.
mkdir -p "$cache"
matugen image "$wall" -c "$config"

# 3. Reload the consumers.
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi
if command -v waybar >/dev/null 2>&1 && pgrep -x waybar >/dev/null; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
fi
