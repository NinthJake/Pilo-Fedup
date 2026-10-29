-- =============================================================================
-- Hyprland configuration (Lua — the official format since Hyprland 0.55)
-- Managed by fedup: edit the copy in ~/.config/fedup/dotfiles/hypr/ and sync.
-- Docs: https://wiki.hypr.land/Configuring/Start/
-- =============================================================================

------------------
---- MONITORS ----
------------------

-- Monitor setup lives in monitors.lua so the pilo Monitors widget can rewrite
-- it independently of the rest of the config. See that file for field meanings.
for _, monitor in ipairs(require("monitors")) do
    hl.monitor(monitor)
end

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "foot"
-- Launcher is the pilo Quickshell bar's app launcher (opens on the focused
-- screen). Was `wofi --show drun`.
local menu        = "qs -c pilo ipc call pilo toggle launcher"
local fileManager = "dolphin"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
    -- pilo bar — Quickshell config at ~/.config/quickshell/pilo. This is the
    -- bar on this setup (waybar is not used). -n exits a duplicate instance so
    -- a Hyprland reload does not stack a second bar.
    hl.exec_cmd("qs -c pilo -n")
    hl.exec_cmd("hyprpaper")
    -- Random per-monitor wallpaper daemon (see random-wallpaper.sh). Long-lived;
    -- waits for hyprpaper's IPC socket itself, so it can start right behind
    -- hyprpaper.
    hl.exec_cmd("~/.config/hypr/random-wallpaper.sh")
    -- Notifications are owned by pilo itself (qs -c pilo above); no separate
    -- notification daemon is started.
    -- Clipboard history: pipe text + image clipboard changes into cliphist.
    -- Each is a long-lived background process (requires wl-paste + cliphist).
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Restore the last-picked wallpaper (or a random pick on a fresh
    -- install) via matugen-apply. Runs after the daemons above so the
    -- hyprpaper IPC socket is up.
    hl.exec_cmd("matugen-apply")
    -- hyprpolkitagent: on PATH on Fedora, /usr/lib/… on Arch (it ships as a
    -- systemd user unit with the binary outside PATH there), so try both.
    hl.exec_cmd("hyprpolkitagent 2>/dev/null || /usr/lib/hyprpolkitagent/hyprpolkitagent")
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

-- The look and feel (colours, gaps, border size, rounding, blur, animations)
-- lives in lookandfeel.lua, which the pilo settings app (Theming) generates
-- from the active theme. On a fresh install that file may not exist before the
-- bar has run once, so fall back to a minimal config — pilo applies the real
-- values live (hyprctl eval) at startup.
local lf_ok, lf = pcall(require, "lookandfeel")
if lf_ok then
    hl.config({
        general    = lf.general,
        decoration = lf.decoration,
        animations = lf.animations,
    })
    for _, anim in ipairs(lf.animation_list or {}) do
        hl.animation(anim)
    end
else
    hl.config({ general = { layout = "dwindle" } })
end

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
        background_color        = (lf_ok and lf.background_color) or 0x1a1a1a,
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
        force_no_accel     = true, -- disable mouse acceleration (1:1 movement)
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

-- Open the pilo app launcher by tapping SUPER alone (fires on release, so it
-- won't trigger when SUPER is used as a modifier for other binds below)
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(menu), { release = true })
-- pilo app launcher (clock, apps, wallpapers) — SUPER+Space.
-- The pilo bar's own launcher, same as the SUPER-tap bind above.
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- "Fake fullscreen" — maximize the focused window so it fills the workspace as
-- if it were the only window there, while keeping gaps, borders and the bar
-- visible. Unlike SUPER+F this is not a real fullscreen: the window stays
-- tiled and no fullscreen request is sent to the app, so switching workspaces
-- and other windows keep working normally. Press again to restore the layout.
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Lock screen (hyprlock) — DISABLED. hyprlock is not used on this setup
-- (it was crashing the session), so no lock keybind is bound.

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
--   ws 1 -> middle (DP-1), ws 2 -> right (HDMI-A-1), ws 3 -> left (DP-2)
hl.workspace_rule({ workspace = "1", monitor = "DP-1",     default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-2",     default = true })

-- Autostart app placement (the apps themselves are launched from
-- ~/.config/autostart): Firefox on the middle screen (ws 1), Vesktop on the
-- right screen (ws 2), Steam on the left screen (ws 3). "silent" = open on
-- the target workspace without switching the view/focus to it. Applies to
-- every new window of the class, not just the autostarted one.
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
    match = {
        class = "^steam$",
        -- Steam's XWayland menus/popups (Steam > Account settings, sign out,
        -- ...) share class "steam" but have an empty title. Without this the
        -- rule would relocate every menu to workspace 3 instead of letting it
        -- follow the main window.
        title = "negative:^$",
    },

    workspace = "3 silent",
})

hl.window_rule({
    name  = "autostart-discord",
    match = { class = "^vesktop$" },

    workspace = "2 silent",
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

-- pilo bar — Quickshell bar. The bar and its anchored popups (calendar,
-- network, sound, bar settings) read as frosted glass. The centered launcher
-- overlay is deliberately not listed: it is a full-screen surface, so blurring
-- it would frost the whole desktop.
hl.layer_rule({
    name  = "blur-pilo",
    match = { namespace = "^pilo-bar$" },

    blur         = true,
    ignore_alpha = 0.2,
    no_anim      = true,
})

-- pilo overlays. All are full-screen surfaces (no blur), but the
-- compositor's fadeLayers animation runs at speed 60 here, which made them
-- take ~4s to fade in. no_anim shows them instantly.
hl.layer_rule({
    name  = "pilo-launcher",
    match = { namespace = "^pilo-launcher$" },

    no_anim = true,
})

hl.layer_rule({
    name  = "pilo-popup",
    match = { namespace = "^pilo-popup$" },

    no_anim = true,
})

hl.layer_rule({
    name  = "pilo-identify",
    match = { namespace = "^pilo-identify$" },

    no_anim = true,
})

-- pilo's notification toasts. They read as the same frosted surface as the
-- bar. no_anim matters for the same reason as the other overlays: the
-- compositor's fadeLayers animation runs at speed 60 here. The cards fade in
-- themselves in QML instead.
hl.layer_rule({
    name  = "pilo-notifications",
    match = { namespace = "^pilo-notifications$" },

    blur         = true,
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

-- HyprMod managed settings
require("hyprland-gui")
