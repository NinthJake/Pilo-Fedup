#!/usr/bin/env bash
# Rotate a random wallpaper per monitor from the pika folder via hyprpaper's
# IPC on a fixed interval. The switch crossfades because of hyprland.lua's
# "wallpaper-crossfade" layer_rule (matches hyprpaper's layer namespace) and
# the "fadeLayers" animation that drives it.
# Runs as a long-lived daemon, started once at Hyprland startup (see
# hyprland.lua AUTOSTART) instead of hyprpaper's own directory rotation
# (timeout/order = random), so each monitor still gets its own random image,
# picked independently, on every rotation rather than just once per session.
# NOTE: current hyprpaper only exposes "wallpaper" and "listactive" over IPC —
# preload/unload/reload were removed (hyprwm/hyprpaper#288). "wallpaper" loads
# straight from disk now, so there's no separate preload/unload step needed
# (or even possible) anymore.
# Docs: https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/#ipc
set -euo pipefail

wallpaper_dir="/home/pilo/Pictures/Wallpapers/pika"
monitors=(HDMI-A-1 DP-1 DP-2)
interval="${WALLPAPER_ROTATE_INTERVAL:-300}" # seconds between rotations

# Wait for hyprpaper's IPC socket to come up (it's started just before this script).
for _ in $(seq 1 40); do
    hyprctl hyprpaper listactive >/dev/null 2>&1 && break
    sleep 0.25
done

declare -A current # monitor -> its currently-set wallpaper path, to dodge repeats

rotate() {
    for monitor in "${monitors[@]}"; do
        local previous=${current[$monitor]:-} wallpaper

        # Re-roll if we land on the same image the monitor already has (only
        # matters when there's more than one candidate); give up after a few
        # tries so a folder with just one image still works.
        for _ in $(seq 1 5); do
            wallpaper=$(find "$wallpaper_dir" -maxdepth 1 -type f | shuf -n 1)
            [[ "$wallpaper" != "$previous" ]] && break
        done

        hyprctl hyprpaper wallpaper "$monitor,$wallpaper" >/dev/null
        current[$monitor]="$wallpaper"
    done
}

rotate
while true; do
    sleep "$interval"
    rotate
done
