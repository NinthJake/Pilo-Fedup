#!/usr/bin/env bash
# Seed pibble's settings.json with fedup-managed defaults on first install.
#
# pibble persists its user config in quickshell's per-shell state dir, keyed
# by an md5 of the path to shell.qml (see the `pibble` script's
# export_icon_theme). This hook writes that file with the wallpaper folder
# pointed at the pika collection and the wallpaper command wired to
# matugen-apply, which sets the wallpaper via hyprpaper AND regenerates the
# matugen colors for Hyprland/waybar.
#
# Only runs when settings.json does not exist yet, so any in-app changes the
# user makes later are never clobbered by a fedup sync.
set -euo pipefail

repo="${PIBBLE_REPO:-$HOME/.config/pibble}"
shell_id=$(printf '%s' "$repo/shell.qml" | md5sum | cut -d' ' -f1)
settings_dir="$HOME/.local/state/quickshell/by-shell/$shell_id"
settings="$settings_dir/settings.json"

[ -f "$settings" ] && exit 0

mkdir -p "$settings_dir"
cat > "$settings" <<'JSON'
{
    "wallpaperDir": "~/Pictures/Wallpapers/pika",
    "wallCommand": "matugen-apply \"$WALL\""
}
JSON
