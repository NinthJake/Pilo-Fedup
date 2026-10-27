#!/bin/sh
# Cycle power profile: performance -> power-saver -> balanced -> performance
# Uses the PowerProfiles D-Bus API served by tuned-ppd (Fedora's default).
# Managed by fedup — waybar power-profiles-daemon on-click runs this.

DEST=net.hadess.PowerProfiles
OBJ=/net/hadess/PowerProfiles
IFACE=net.hadess.PowerProfiles

cur=$(busctl get-property "$DEST" "$OBJ" "$IFACE" ActiveProfile 2>/dev/null | cut -d'"' -f2)

case "$cur" in
    performance) next=power-saver ;;
    power-saver) next=balanced ;;
    *)           next=performance ;;
esac

busctl set-property "$DEST" "$OBJ" "$IFACE" ActiveProfile s "$next"
