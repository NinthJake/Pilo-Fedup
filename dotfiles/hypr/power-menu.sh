#!/bin/sh
# Power/session menu for Hyprland — wofi dmenu (managed by fedup)
# Bound to SUPER+Esc in hyprland.lua. Esc closes with no action.

choice=$(printf 'Lock\nLogout\nSuspend\nReboot\nShutdown' |
    wofi --dmenu --prompt "Power" --cache-file /dev/null --width 320 --height 245)

case "$choice" in
    Lock)     hyprlock ;;
    Logout)   hyprctl dispatch 'hl.dsp.exit()' ;;
    Suspend)  systemctl suspend ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
