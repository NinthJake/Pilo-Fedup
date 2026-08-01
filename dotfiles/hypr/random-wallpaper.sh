#!/usr/bin/env bash
# Pick one random wallpaper per monitor from the pika folder and apply it once
# via hyprpaper's IPC. Run at Hyprland startup (see hyprland.lua AUTOSTART)
# instead of hyprpaper's own directory rotation (timeout/order = random):
# this way each monitor still gets a different random image, but it's picked
# once per session and never rotates again until the next login.
# Docs: https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/#ipc
set -euo pipefail

wallpaper_dir="/home/pilo/Pictures/Wallpapers/pika"
monitors=(HDMI-A-1 DP-1 DP-2)

# Wait for hyprpaper's IPC socket to come up (it's started just before this script).
for _ in $(seq 1 40); do
    hyprctl hyprpaper listactive >/dev/null 2>&1 && break
    sleep 0.25
done

for monitor in "${monitors[@]}"; do
    wallpaper=$(find "$wallpaper_dir" -maxdepth 1 -type f | shuf -n 1)
    hyprctl hyprpaper wallpaper "$monitor,$wallpaper" >/dev/null
done
