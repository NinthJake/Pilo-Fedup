-- =============================================================================
-- Hyprland configuration (Lua — the official format since Hyprland 0.55)
-- Managed by fedup: edit the copy in ~/.config/fedup/dotfiles/hypr/ and sync.
-- Docs: https://wiki.hypr.land/Configuring/Start/
-- =============================================================================

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@60",
    position = "auto-right",
    scale    = "1",
})

hl.monitor({
    output   = "DP-2",
    mode     = "2560x1440@60",
    position = "auto-left",
    scale    = "auto",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "foot"
local menu        = "wofi --show drun"
local fileManager = "dolphin"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
    -- Start waybar via its systemd user service (shipped by the waybar
    -- package; Restart=on-failure auto-respawns it if a module crashes, e.g.
    -- the known mpris/playerctl segfault). --user, since it's a session
    -- process needing WAYLAND_DISPLAY.
    hl.exec_cmd("systemctl --user start waybar.service")
    hl.exec_cmd("hyprpaper")
    -- Random per-monitor wallpaper daemon (see random-wallpaper.sh). Long-lived;
    -- waits for hyprpaper's IPC socket itself, so it can start right behind
    -- hyprpaper. Pauses automatically when a wallpaper is picked in pibble.
    hl.exec_cmd("~/.config/hypr/random-wallpaper.sh")
    -- pibble — desktop shell (launcher, notification/volume flyouts, wallpaper
    -- picker). Started as a persistent daemon; SUPER+Space toggles the
    -- launcher. pibble owns org.freedesktop.Notifications, so mako is no
    -- longer started here.
    hl.exec_cmd("pibble start")
    -- Clipboard watchers for pibble's clipboard history: pipe text + image
    -- clipboard changes into cliphist (which pibble reads). Each is a
    -- long-lived background process. Requires wl-paste.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Restore the last-picked wallpaper (or a random pick on a fresh
    -- install) via matugen-apply. Runs after the daemons above so the
    -- hyprpaper IPC socket is up.
    hl.exec_cmd("matugen-apply")
    hl.exec_cmd("hyprpolkitagent")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt/KDE apps (Dolphin, Okular, ...): use KDE's platform theme so they
-- follow your dark KDE colors under Hyprland instead of Qt's light default
hl.env("QT_QPA_PLATFORMTHEME", "kde")
-- No server-side double title bars on Qt apps (standard Hyprland setup)
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- GPU-specific environment — detected from loaded kernel modules, so this
-- config is portable across NVIDIA / AMD / Intel machines
local function kernel_module_loaded(name)
    local f = io.open("/proc/modules", "r")
    if not f then return false end
    local found = f:read("*a"):find(name) ~= nil
    f:close()
    return found
end

if kernel_module_loaded("nvidia") then
    -- NVIDIA proprietary driver (akmod/kmod-nvidia)
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
elseif kernel_module_loaded("amdgpu") then
    -- AMD (radeonsi) — helps VAAPI/video acceleration
    hl.env("LIBVA_DRIVER_NAME", "radeonsi")
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 4,
        border_size = 2,

        -- vague.nvim palette: teal builtin -> steel keyword gradient, muted
        -- comment inactive. (Kept hardcoded — the matugen palette was too
        -- subtle to read as a focus highlight.)
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

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 8,
            passes   = 2,
            vibrancy = 0.1696,

            -- Hyprland 0.56 defaults ignore_opacity to true, which on this
            -- setup kills window blur entirely (translucent windows show the
            -- wallpaper razor-sharp instead of frosted). Force it off.
            ignore_opacity = false,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.animation({ leaf = "windows",    enabled = true, speed = 4.79, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3.03, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "default", style = "fade" })
-- Layer surfaces (waybar, mako, wofi, hyprpaper, ...) get their own fade
-- animation, separate from "fade" above; this is what makes the hyprpaper
-- crossfade below (and the other layer_rules further down) actually animate.
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 60, bezier = "default" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0, -- 0/1 disables the anime mascot wallpaper
        disable_hyprland_logo   = true,
        background_color        = 0x1a1a1a,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout          = "se",
        follow_mouse       = 1,
        sensitivity        = 0,
        numlock_by_default = true, -- turn Num Lock on at startup

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Windows key

hl.bind(mainMod .. " + Return",    hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))

-- Open the app launcher by tapping SUPER alone (fires on release, so it
-- won't trigger when SUPER is used as a modifier for other binds below)
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(menu), { release = true })
-- pibble launcher (clock, apps, wallpapers, clipboard) — SUPER+Space
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("pibble toggle"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Lock screen (hyprlock) — DISABLED. hyprlock is not used on this setup
-- (it was crashing the session), so no lock keybind is bound.

-- Power/session menu (lock, logout, suspend, reboot, shutdown) — SUPER+Esc
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("~/.config/hypr/power-menu.sh"))

-- Focus with mainMod + arrows and vim keys (hjkl)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Minimize the active window to a special workspace, restore it on next press.
-- One bind, one window at a time — see "Minimize windows using special workspaces":
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Uncommon-tips-and-tricks/
hl.bind(mainMod .. " + X", function ()
    if hl.get_workspace("special:minimized") then
        hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace(), window = "tag:minimized" }))
        hl.dispatch(hl.dsp.window.clear_tags({ window = "tag:minimized" }))
    else
        hl.dispatch(hl.dsp.window.tag({ tag = "minimized", window = hl.get_active_window() }))
        hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
    end
end)

-- Cycle workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows by dragging with mainMod + LMB/RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots: Print = select area, SHIFT+Print = full screen (both to clipboard)
hl.bind(mainMod .. " + P",         hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy && notify-send -t 2000 "Screenshot" "Area copied to clipboard"]]))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd([[grim - | wl-copy && notify-send -t 2000 "Screenshot" "Fullscreen copied to clipboard"]]))

-- Volume and brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media keys
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Deterministic home workspaces per screen, so autostart apps and the
-- SUPER+[0-9] binds always land on the same monitor:
--   ws 1-2 -> middle (HDMI-A-1), ws 3 -> left (DP-2), ws 10 -> right (DP-1)
hl.workspace_rule({ workspace = "1",  monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3",  monitor = "DP-2",     default = true })
hl.workspace_rule({ workspace = "10", monitor = "DP-1",     default = true })

-- Autostart app placement (the apps themselves are launched from
-- ~/.config/autostart): Firefox + Steam on the middle screen, Discord on the
-- right screen. "silent" = open on the target workspace without switching
-- the view/focus to it. Applies to every new window of the class, not just
-- the autostarted one.
hl.window_rule({
    name  = "autostart-firefox",
    match = {
        class = "^(firefox|org\\.mozilla\\.firefox)$",
        -- ...but not picture-in-picture popups; those stay where you are
        title = "negative:^[Pp]icture[- ]in[- ][Pp]icture$",
    },

    workspace = "1 silent",
})

hl.window_rule({
    name  = "autostart-steam",
    match = { class = "^steam$" },

    workspace = "2 silent",
})

hl.window_rule({
    name  = "autostart-discord",
    match = { class = "^vesktop$" },

    workspace = "10 silent",
})

hl.window_rule({
    -- Browser picture-in-picture windows always float
    -- (Firefox: "Picture-in-Picture", Chromium/Brave: "Picture in picture")
    name  = "float-pip",
    match = { title = "^[Pp]icture[- ]in[- ][Pp]icture$" },

    float = true,
})

hl.window_rule({
    -- Ignore maximize requests from all apps
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Force full opacity for apps that render their own translucency/blur
    -- (or that just look wrong with the compositor's opacity/blur applied on
    -- top, e.g. games): terminal, browser, RuneLite, Steam games, gamescope.
    -- Adjust the class list to match `hyprctl clients` on this machine.
    name  = "no-compositor-opacity",
    match = { class = "^(foot|brave-origin-nightly|net-runelite.*|steam_app_.*|gamescope)$" },

    opacity = "1.0 override 1.0 override 1.0 override",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

----------------
---- LAYERS ----
----------------

hl.layer_rule({
    name  = "blur-waybar",
    match = { namespace = "^waybar$" },

    blur         = true,
    ignore_alpha = 0.2,
    no_anim      = true,
})

-- mako's layer namespace is "notifications" (verified with `hyprctl layers`).
-- Mirrors "blur-waybar" so notifications read the same as the bar; animation is
-- left enabled here, unlike waybar, so notifications still fade in.
hl.layer_rule({
    name  = "blur-notifications",
    match = { namespace = "^notifications$" },

    blur         = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    name  = "blur-wofi",
    match = { namespace = "^wofi$" },

    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.2,
    no_anim      = true,
})

-- Crossfade hyprpaper's wallpaper on change (e.g. from random-wallpaper.sh or
-- `hyprctl hyprpaper wallpaper`) instead of an abrupt swap. Needs the
-- "fadeLayers" animation above enabled to actually animate.
hl.layer_rule({
    name  = "wallpaper-crossfade",
    match = { namespace = "^hyprpaper$" },

    animation = "fade",
})

-- pibble — desktop shell layer surfaces (launcher + notification/volume
-- flyouts). Blur the launcher and flyouts like waybar/wofi so they read as
-- frosted glass over the desktop; the launcher's own backdrop is handled by
-- pibble's in-app "xray" blur setting, so compositor blur here is a light
-- touch. Namespaces: pibble-launcher, pibble-notifications, pibble-volume.
hl.layer_rule({
    name  = "blur-pibble",
    match = { namespace = "^(pibble-launcher|pibble-notifications|pibble-volume)$" },

    blur         = true,
    ignore_alpha = 0.2,
})
