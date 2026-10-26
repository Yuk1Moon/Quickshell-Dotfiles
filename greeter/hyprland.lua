-- /etc/greetd/hyprland.lua
-- Compositor config for the greetd greeter session.
--
-- Self-contained on purpose. It does not read anything from /home: the greeter
-- runs as the `greeter` user, which cannot traverse a drwx------ home anyway.
--
-- The display and input values below are copied from the desktop session
-- (~/.config/hypr/hyprland.lua). If you change scale or keyboard layout there,
-- change them here too.

-- Display. scale = "auto" is what makes HiDPI panels render at a sane size;
-- without it Hyprland defaults to scale 1 and everything comes out half-size.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Cursor size, so the pointer does not jump in size across the login boundary.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Keyboard. This one genuinely matters: a mismatched layout means the password
-- you type is not the password that gets sent.
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "altgr-intl",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Launch the greeter shell. When `qs` exits (the user logged in, so greetd will
-- start the real session once this process is gone) tear the compositor down.
-- systemd-cat keeps the shell's own output off the console (it would be drawn
-- on the VT otherwise) and puts it somewhere readable: journalctl -t greeter
hl.on("hyprland.start", function()
    hl.exec_cmd("systemd-cat --identifier=greeter qs -c greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)

-- Rescue bind: if the greeter fails to come up, this drops back to greetd,
-- which simply restarts it. Without it a broken shell means a dead VT.
--
-- Deliberately the only bind here. Anything that spawns a program would be
-- reachable by whoever is sitting at the login screen, before authentication.
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

-- No windows are ever mapped here, so decoration and animations are pointless.
hl.config({
    animations = {
        enabled = false,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})
