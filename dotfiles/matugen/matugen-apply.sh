#!/usr/bin/env bash
# Set a wallpaper on every monitor via hyprpaper, pinning it if it was picked
# explicitly (so random-wallpaper.sh stops rotating for the session). Managed
# by fedup.
#
# Usage:
#   matugen-apply <image>   set wallpaper + pin it (pibble pick)
#   matugen-apply           restore pibble's last-picked wallpaper (login)
#
# Wired into pibble's wallCommand (see seed-settings.sh) and Hyprland's
# autostart. The name is kept for the symlink/wiring; matugen color generation
# was removed when the hyprland/waybar themes went back to hardcoded
# vague.nvim colors.
set -euo pipefail

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

# Set the wallpaper on every monitor via hyprpaper.
if command -v hyprctl >/dev/null 2>&1; then
    # hyprpaper may not have its IPC socket up yet when this runs at login
    # (hyprland.lua autostarts it and this script back-to-back), which used to
    # make the wallpaper sets below fail silently. Wait for the socket first.
    for _ in $(seq 1 40); do
        hyprctl hyprpaper listactive >/dev/null 2>&1 && break
        sleep 0.25
    done
    for m in $(hyprctl monitors -j | jq -r '.[].name'); do
        hyprctl hyprpaper wallpaper "$m,$wall" >/dev/null
    done
fi

# A wallpaper was picked explicitly (e.g. from the pibble launcher): pin it by
# telling random-wallpaper.sh to stop rotating for this session. No-op on the
# bare login run (no argument), so rotation still kicks in at startup.
if [ -n "${1:-}" ]; then
    touch "$HOME/.cache/random-wallpaper-pinned"
fi
