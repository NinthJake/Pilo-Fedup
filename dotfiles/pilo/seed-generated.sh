#!/usr/bin/env bash
# Seed pilo's generated theme files at install time, so a fresh install works
# before the bar has run once:
#
#   - foot.ini includes ~/.config/foot/colors.ini, and foot refuses to start if
#     an included file is missing.
#   - hyprland.lua requires ~/.config/hypr/lookandfeel.lua (with a pcall
#     fallback, but then the first session uses Hyprland's defaults).
#
# The pilo bar (Theming category) overwrites both on first start and on every
# theme change, so these are only bootstrap defaults (the Vague palette). Each
# file is written only when missing, so a sync never clobbers a running system.
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}"

foot_colors="$config/foot/colors.ini"
if [ ! -f "$foot_colors" ]; then
    mkdir -p "$(dirname "$foot_colors")"
    cat > "$foot_colors" <<'EOF'
# Seed default (Vague). The pilo bar (Theming) regenerates this.
[colors-dark]
background=141415
foreground=cdcdcd
regular0=252530
regular1=d8647e
regular2=7fa563
regular3=f3be7c
regular4=6e94b2
regular5=b4d4cf
regular6=92afc5
regular7=cdcdcd
bright0=606079
bright1=e28b9e
bright2=9fbc8a
bright3=f6ce9d
bright4=9ab4c9
bright5=c7dfdb
bright6=afc4d5
bright7=dcdcdc
selection-foreground=141415
selection-background=b4d4cf
cursor=141415 b4d4cf
EOF
fi

look="$config/hypr/lookandfeel.lua"
if [ ! -f "$look" ]; then
    mkdir -p "$(dirname "$look")"
    cat > "$look" <<'EOF'
-- Seed default (Vague). The pilo bar (Theming) regenerates this.
return {
    general = {
        gaps_in     = 2,
        gaps_out    = 4,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(b4d4cfee)", "rgba(6e94b2ee)" }, angle = 45 },
            inactive_border = "rgba(606079aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding       = 2,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur = {
            enabled  = true,
            size     = 8,
            passes   = 2,
            vibrancy = 0.1696,
            ignore_opacity = false,
        },
    },
    animations = { enabled = true },
    animation_list = {
        { leaf = "windows",    enabled = true, speed = 4.79, bezier = "default" },
        { leaf = "fade",       enabled = true, speed = 3.03, bezier = "default" },
        { leaf = "workspaces", enabled = true, speed = 1.94, bezier = "default", style = "fade" },
        { leaf = "fadeLayers", enabled = true, speed = 60,   bezier = "default" },
    },
    background_color = 0x1a1a1a,
}
EOF
fi
