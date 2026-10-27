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
# a random pick from the wallpaper collections (fresh install before any pick).
wall="${1:-}"
if [ -z "$wall" ]; then
    shell_id=$(printf '%s' "$HOME/.config/pibble/shell.qml" | md5sum | cut -d' ' -f1)
    wall=$(jq -r '.currentWallpaper // empty' \
        "$HOME/.local/state/quickshell/by-shell/$shell_id/settings.json" 2>/dev/null || true)
fi
if [ -z "$wall" ] || [ ! -f "$wall" ]; then
    # Searched recursively: one subfolder per collection (pika/, MLFW/, …).
    wall=$(find "$HOME/Pictures/Wallpapers" -type f 2>/dev/null | shuf -n 1)
fi
[ -n "$wall" ] && [ -f "$wall" ] || { echo "matugen-apply: no wallpaper found" >&2; exit 1; }

# Set the wallpaper on every monitor via hyprpaper.
if command -v hyprctl >/dev/null 2>&1; then
    # hyprpaper may not have its IPC socket up yet when this runs at login
    # (hyprland.lua autostarts it and this script back-to-back), which used to
    # make the wallpaper sets below fail silently. Wait for the socket first —
    # Hyprland 0.56 dropped `hyprctl hyprpaper listactive`, so poll the socket
    # hyprpaper creates instead.
    hp_sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.hyprpaper.sock"
    for _ in $(seq 1 40); do
        [ -S "$hp_sock" ] && break
        sleep 0.25
    done
    # awk instead of jq for the monitor names: this script is shared with the
    # Fedora machine, whose package list has no jq.
    for m in $(hyprctl monitors | awk '/^Monitor /{print $2}'); do
        hyprctl hyprpaper wallpaper "$m,$wall" >/dev/null
    done
fi

# A wallpaper was picked explicitly (e.g. from the pibble launcher): pin it by
# telling random-wallpaper.sh to stop rotating for this session. No-op on the
# bare login run (no argument), so rotation still kicks in at startup.
if [ -n "${1:-}" ]; then
    touch "$HOME/.cache/random-wallpaper-pinned"
fi
