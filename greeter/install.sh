#!/usr/bin/env bash
# Installs the greeter. Run with sudo:  sudo ./install.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST=/etc/xdg/quickshell/greeter
GREETD=/etc/greetd

# Wallpaper for the login screen. Copied into /etc because the greeter user
# cannot read anything under a drwx------ home.
#
# Defaults to whatever hyprpaper shows on the desktop, read fresh on every run,
# so changing hyprpaper.conf and re-running this script keeps the two in step.
#   sudo WALLPAPER=/path/to/image.png ./install.sh   use a different image
#   sudo WALLPAPER= ./install.sh                     no wallpaper, plain gradient
if [[ -z ${WALLPAPER+x} ]]; then
	# $HOME is root's under sudo, so resolve the invoking user's home instead.
	_home=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
	_hyprpaper="$_home/.config/hypr/hyprpaper.conf"
	if [[ -r $_hyprpaper ]]; then
		WALLPAPER=$(grep -E '^[[:space:]]*path[[:space:]]*=' "$_hyprpaper" \
			| head -1 | sed 's/^[^=]*=[[:space:]]*//; s/[[:space:]]*$//')
		WALLPAPER="${WALLPAPER/#\~/$_home}"
	else
		WALLPAPER=""
	fi
fi

if [[ $EUID -ne 0 ]]; then
	echo "Run this with sudo." >&2
	exit 1
fi

echo ":: validating sources"
luac -p "$SRC/hyprland.lua"
python3 -c "import ast,sys; ast.parse(open('$SRC/greetd-ipc.py').read())"
for f in "$SRC"/*.qml; do
	qmllint -I /usr/lib/qt6/qml "$f"
done

echo ":: giving the greeter user a writable home"
# greeter's home is / by default, which it cannot write to. Quickshell copes,
# but a real home keeps its cache and any Qt state out of the way.
install -d -o greeter -g greeter -m 0755 /var/lib/greetd
usermod -d /var/lib/greetd greeter

echo ":: installing shell to $DEST"
install -d -m 0755 "$DEST"
for f in shell.qml Theme.qml Time.qml Greetd.qml; do
	install -m 0644 "$SRC/$f" "$DEST/$f"
done
install -m 0755 "$SRC/greetd-ipc.py" "$DEST/greetd-ipc.py"

if [[ -n $WALLPAPER ]]; then
	if [[ -r $WALLPAPER ]]; then
		echo ":: installing wallpaper to $GREETD/wallpaper.png"
		echo "   source: $WALLPAPER"
		install -m 0644 "$WALLPAPER" "$GREETD/wallpaper.png"
	else
		echo "   WARNING: cannot read $WALLPAPER, skipping wallpaper." >&2
		echo "   The greeter falls back to its gradient background." >&2
	fi
elif [[ -f $GREETD/wallpaper.png ]]; then
	# Asked for no wallpaper: drop the one a previous run installed, otherwise
	# the greeter keeps showing it and this run silently did nothing.
	echo ":: removing previously installed wallpaper"
	rm -f "$GREETD/wallpaper.png"
fi

echo ":: installing compositor config to $GREETD/hyprland.lua"
if [[ -f $GREETD/hyprland.lua ]] && ! cmp -s "$SRC/hyprland.lua" "$GREETD/hyprland.lua"; then
	cp -a "$GREETD/hyprland.lua" "$GREETD/hyprland.lua.bak.$(date +%s)"
	echo "   (previous version backed up)"
fi
install -m 0644 "$SRC/hyprland.lua" "$GREETD/hyprland.lua"

echo ":: checking greetd config"
if ! grep -q 'hyprland.lua' "$GREETD/config.toml"; then
	echo "   WARNING: $GREETD/config.toml does not reference hyprland.lua." >&2
	echo "   Expected: command = \"start-hyprland -- -c /etc/greetd/hyprland.lua\"" >&2
fi

echo ":: verifying the greeter user can read everything"
check_greeter_can_read() {
	if sudo -u greeter test "$1" "$2"; then
		echo "   $(basename "$2") ok"
	else
		echo "   FAILED: the greeter user cannot access $2" >&2
		exit 1
	fi
}
check_greeter_can_read -r "$DEST/shell.qml"
check_greeter_can_read -x "$DEST/greetd-ipc.py"
if [[ -f $GREETD/wallpaper.png ]]; then
	check_greeter_can_read -r "$GREETD/wallpaper.png"
fi

echo
echo "Installed. Nothing is enabled yet; boot behaviour is unchanged."
echo
echo "To enable it:"
echo "  sudo systemctl enable greetd   # note: enable, NOT enable --now"
echo "  reboot"
echo
echo "greetd is configured for VT 1, which a running graphical session is"
echo "already using, so starting it right now would fight the live session."
echo "Enabling it and rebooting makes the first real run a clean one."
echo
echo "If the greeter misbehaves: Ctrl+Alt+F2 gives a text login, then"
echo "  sudo systemctl disable greetd && sudo systemctl start getty@tty1"
