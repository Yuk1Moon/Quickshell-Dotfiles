#!/usr/bin/env bash
# Runs the greeter inside a nested Hyprland against a fake greetd, so you can
# iterate without touching the real login path. Password is "demo".
#
#   ./test-nested.sh
#
# Close the nested window with SUPER+SHIFT+E.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"

# Preview against the real wallpaper, straight out of $HOME. The installed
# greeter reads /etc/greetd/wallpaper.png instead, since it runs as `greeter`.
# Read it out of hyprpaper.conf so this does not drift from the desktop.
if [[ -z ${QS_GREETER_WALLPAPER-} && -r $HOME/.config/hypr/hyprpaper.conf ]]; then
	_wp=$(grep -oE 'path *= *\S+' "$HOME/.config/hypr/hyprpaper.conf" | head -1 | sed 's/.*= *//')
	_wp="${_wp/#\~/$HOME}"
	[[ -r $_wp ]] && export QS_GREETER_WALLPAPER="$_wp"
fi
[[ -n ${QS_GREETER_WALLPAPER-} ]] && echo "Wallpaper: $QS_GREETER_WALLPAPER"
trap 'rm -rf "$TMP"; kill %1 2>/dev/null || true' EXIT

cat > "$TMP/fake-greetd.py" <<'PY'
import json, os, socket, struct, sys, threading
P = sys.argv[1]
srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); srv.bind(P); srv.listen(5)
def handle(c):
    # Mirrors the real greetd: a failed attempt leaves the session under
    # configuration, and every create_session is refused until it is cancelled.
    state = {"session": False}
    def send(o):
        p = json.dumps(o).encode(); c.sendall(struct.pack("=I", len(p)) + p)
    def recv():
        h = b""
        while len(h) < 4:
            ch = c.recv(4 - len(h))
            if not ch: return None
            h += ch
        n = struct.unpack("=I", h)[0]; buf = b""
        while len(buf) < n: buf += c.recv(n - len(buf))
        return json.loads(buf)
    while True:
        r = recv()
        if r is None: break
        print("greetd <<", r, flush=True)
        t = r.get("type")
        if t == "create_session":
            if state["session"]:
                send({"type": "error", "error_type": "error",
                      "description": "a session already exists"})
            else:
                state["session"] = True
                send({"type": "auth_message", "auth_message_type": "secret", "auth_message": "Password:"})
        elif t == "post_auth_message_response":
            if r.get("response") == "demo":
                send({"type": "success"})
            else:
                # Real greetd tears the session worker down on an auth failure,
                # so nothing is left to cancel afterwards.
                state["session"] = False
                send({"type": "error", "error_type": "auth_error",
                      "description": "pam_authenticate: AUTH_ERR"})
        elif t == "start_session":
            print("greetd >> would start:", r.get("cmd"), r.get("env"), flush=True)
            send({"type": "success"})
        elif t == "cancel_session":
            if state["session"]:
                state["session"] = False
                send({"type": "success"})
            else:
                # What greetd actually answers when the worker is already gone.
                send({"type": "error", "error_type": "error",
                      "description": "unable to send message: Connection refused (os error 111)"})
while True:
    c, _ = srv.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
PY

cat > "$TMP/test.lua" <<LUA
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p $SRC")
end)
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())
-- scale 1 keeps the nested output's logical size equal to its pixel size, so
-- what you see here maps 1:1 to what the real greeter draws.
hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = 1 })
hl.config({
    general = { border_size = 0, gaps_in = 0, gaps_out = 0 },
    animations = { enabled = false },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true, disable_splash_rendering = true },
    input = { kb_layout = "us", kb_variant = "altgr-intl" },
})
LUA

python3 "$TMP/fake-greetd.py" "$TMP/greetd.sock" &
sleep 1
echo "Nested greeter starting. Password: demo   Quit: SUPER+SHIFT+E"
AQ_WAYLAND_OUTPUTS=1 GREETD_SOCK="$TMP/greetd.sock" Hyprland -c "$TMP/test.lua"
