#!/usr/bin/env python3
"""Bridge between Quickshell and greetd.

Quickshell can only speak newline-delimited text over a Process' stdio, while
greetd speaks length-prefixed JSON over the socket in $GREETD_SOCK (see
greetd-ipc(7)). This translates between the two, one JSON object per line in
each direction.

It also emits a synthetic "ready" event on startup carrying the local users and
the installed sessions, so the QML side never has to parse /etc/passwd or
.desktop files itself.
"""

import json
import os
import pwd
import socket
import struct
import sys
import threading
import glob
from shutil import which

HEADER = "=I"  # 32-bit length, native byte order
HEADER_SIZE = struct.calcsize(HEADER)

out_lock = threading.Lock()


def emit(obj):
    """Write one event to Quickshell."""
    with out_lock:
        sys.stdout.write(json.dumps(obj) + "\n")
        sys.stdout.flush()


def list_users():
    users = []
    for p in pwd.getpwall():
        if not (1000 <= p.pw_uid < 60000):
            continue
        if os.path.basename(p.pw_shell) in ("nologin", "false", ""):
            continue
        users.append({
            "name": p.pw_name,
            "display": (p.pw_gecos or "").split(",")[0] or p.pw_name,
        })
    return sorted(users, key=lambda u: u["name"])


def list_sessions():
    sessions = []
    for path in sorted(glob.glob("/usr/share/wayland-sessions/*.desktop") +
                       glob.glob("/usr/share/xsessions/*.desktop")):
        entry = {}
        for line in open(path, encoding="utf-8", errors="replace"):
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                key, _, value = line.partition("=")
                entry.setdefault(key.strip(), value.strip())
        if "Exec" not in entry or entry.get("Hidden", "").lower() == "true":
            continue
        # TryExec names a binary that must exist for the entry to be usable;
        # hyprland-uwsm.desktop ships even when uwsm is not installed.
        try_exec = entry.get("TryExec")
        if try_exec and not which(try_exec):
            continue
        # Drop .desktop field codes (%U, %f, ...); they mean nothing here.
        argv = [a for a in entry["Exec"].split() if not a.startswith("%")]
        if not argv:
            continue
        sessions.append({
            "name": entry.get("Name", os.path.basename(path)),
            "cmd": argv,
            "xdgDesktop": entry.get("DesktopNames", ""),
            "wayland": "wayland-sessions" in path,
        })
    return sessions


def main():
    sock_path = os.environ.get("GREETD_SOCK")
    if not sock_path:
        emit({"type": "error", "error_type": "error",
              "description": "GREETD_SOCK is not set; not running under greetd"})
        return 1

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.connect(sock_path)
    except OSError as e:
        emit({"type": "error", "error_type": "error",
              "description": f"cannot connect to {sock_path}: {e}"})
        return 1

    def recv_exact(n):
        buf = b""
        while len(buf) < n:
            chunk = sock.recv(n - len(buf))
            if not chunk:
                return None
            buf += chunk
        return buf

    def reader():
        while True:
            header = recv_exact(HEADER_SIZE)
            if header is None:
                break
            payload = recv_exact(struct.unpack(HEADER, header)[0])
            if payload is None:
                break
            try:
                emit(json.loads(payload))
            except ValueError as e:
                emit({"type": "error", "error_type": "error",
                      "description": f"bad reply from greetd: {e}"})
        emit({"type": "disconnected"})

    threading.Thread(target=reader, daemon=True).start()

    emit({"type": "ready", "users": list_users(), "sessions": list_sessions()})

    # Commands in: one JSON request per line, forwarded verbatim to greetd.
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        line = line.strip()
        if not line:
            continue
        try:
            payload = json.dumps(json.loads(line)).encode("utf-8")
        except ValueError as e:
            emit({"type": "error", "error_type": "error",
                  "description": f"bad request from shell: {e}"})
            continue
        try:
            sock.sendall(struct.pack(HEADER, len(payload)) + payload)
        except OSError as e:
            emit({"type": "error", "error_type": "error",
                  "description": f"write to greetd failed: {e}"})
            break

    return 0


if __name__ == "__main__":
    sys.exit(main())
