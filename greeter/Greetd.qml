// Greetd.qml
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Drives the greetd login flow through greetd-ipc.py.
//
// The flow per greetd-ipc(7): create_session -> zero or more auth_message
// exchanges -> success -> start_session -> success -> the greeter must exit,
// and only then does greetd launch the session.
Singleton {
	id: root

	// Populated from the helper's synthetic "ready" event.
	property var users: []
	property var sessions: []
	property bool connected: false

	// Current prompt, empty when we are not waiting on an answer.
	property string prompt: ""
	property bool promptSecret: true
	property bool awaitingPrompt: false

	property string message: ""
	property bool messageIsError: false

	// True from create_session until the flow settles, to lock the UI.
	property bool busy: false

	// The session command chosen in the UI, applied once authentication passes.
	property var sessionCmd: ["/usr/bin/start-hyprland"]
	property string sessionDesktop: "Hyprland"
	property bool sessionWayland: true

	signal authenticated
	signal sessionStarted

	// What we are waiting for a "success" to mean: "auth" or "start".
	property string _pending: ""
	property string _username: ""

	function _send(obj) {
		proc.write(JSON.stringify(obj) + "\n");
	}

	function login(username) {
		if (root.busy)
			return;
		root._username = username;
		root._pending = "auth";
		root.busy = true;
		root.message = "";
		root.messageIsError = false;
		root._send({ type: "create_session", username: username });
	}

	function respond(answer) {
		if (!root.awaitingPrompt)
			return;
		root.awaitingPrompt = false;
		root.prompt = "";
		root._send({ type: "post_auth_message_response", response: answer });
	}

	function cancel() {
		root.awaitingPrompt = false;
		root.prompt = "";
		// busy stays set until greetd acknowledges; see the "cancel" case above.
		root._pending = "cancel";
		root._send({ type: "cancel_session" });
	}

	function _startSession() {
		root._pending = "start";
		const env = [
			"XDG_SESSION_DESKTOP=" + root.sessionDesktop,
			"XDG_CURRENT_DESKTOP=" + root.sessionDesktop,
			"XDG_SESSION_TYPE=" + (root.sessionWayland ? "wayland" : "x11")
		];

		// greetd hands the session the VT itself as stdout, so everything the
		// compositor prints while starting lands on the console — visible for the
		// couple of seconds between this greeter exiting and the session taking
		// over the screen. systemd-cat execs the command with stdout and stderr
		// pointed at the journal instead, so the console stays blank.
		const cmd = ["systemd-cat", "--identifier=session"].concat(root.sessionCmd);

		root._send({ type: "start_session", cmd: cmd, env: env });
	}

	// greetd forwards PAM's own wording, which is written for sysadmins reading
	// logs, not for someone standing at a login screen. A mistyped username comes
	// through as "pam_authenticate: SERVICE_ERR", which reads like the machine is
	// broken. Translate the auth failures and pass anything else through: a real
	// system fault should still be visible, not swallowed by a friendly phrase.
	// greetd forwards PAM's own wording, which is written for sysadmins reading
	// logs, not for someone standing at a login screen. A mistyped username comes
	// through as "pam_authenticate: SERVICE_ERR", which reads like the machine is
	// broken. Translate the auth failures and pass anything else through: a real
	// system fault should still be visible, not swallowed by a friendly phrase.
	//
	// Order matters. The specific cases have to be tested before the catch-all
	// pam_* pattern, which would otherwise claim all of them.
	function _humanError(msg) {
		const raw = (msg.description || "").trim();

		if (/MAXTRIES|faillock/i.test(raw))
			return "Too many attempts. Wait and try again.";

		if (/ACCT_EXPIRED|NEW_AUTHTOK_REQD|CRED_EXPIRED|PERM_DENIED/i.test(raw))
			return "This account cannot log in. See the system administrator.";

		// Deliberately not saying which of the two was wrong: SERVICE_ERR is
		// PAM's generic failure and only happens to mean "no such user" here.
		if (msg.error_type === "auth_error"
			|| /pam_\w+:|SERVICE_ERR|AUTH_ERR|USER_UNKNOWN|CRED_INSUFFICIENT/i.test(raw))
			return "Incorrect username or password";

		return raw !== "" ? raw : "Login failed";
	}

	function _handle(msg) {
		switch (msg.type) {
		case "ready":
			root.connected = true;
			root.users = msg.users;
			root.sessions = msg.sessions;
			break;

		case "auth_message":
			// info/error messages still need an answer to advance the flow,
			// but carry no response payload.
			if (msg.auth_message_type === "info" || msg.auth_message_type === "error") {
				root.message = msg.auth_message;
				root.messageIsError = msg.auth_message_type === "error";
				root._send({ type: "post_auth_message_response" });
			} else {
				root.prompt = msg.auth_message;
				root.promptSecret = msg.auth_message_type === "secret";
				root.awaitingPrompt = true;
			}
			break;

		case "success":
			if (root._pending === "auth") {
				root.authenticated();
				root._startSession();
			} else if (root._pending === "start") {
				root._pending = "";
				root.sessionStarted();
			} else if (root._pending === "cancel") {
				// greetd has let go of the lingering session. Only now can another
				// create_session succeed, so this is where the retry unlocks.
				root._pending = "";
				root.busy = false;
				root.message = "Try again";
				root.messageIsError = false;
			}
			break;

		case "error":
			root.awaitingPrompt = false;
			root.prompt = "";

			// Keep the untranslated text where it is useful: journalctl -t greeter
			console.warn("greetd error:", msg.error_type, "-", msg.description);

			if (root._pending === "cancel") {
				// The cancel itself failed. Asking again would loop forever.
				root._pending = "";
				root.busy = false;
				root.message = root._humanError(msg);
				root.messageIsError = true;
				break;
			}

			// greetd tears down its session worker itself when authentication
			// fails, so there is normally nothing left to cancel. Sending
			// cancel_session unprompted just earns a second error -- "unable to
			// send message: Connection refused" -- which lands on top of the
			// message the user actually needed to read.
			//
			// Only when greetd says a session is still lingering is a cancel the
			// right move; then the retry is unlocked once it is acknowledged.
			if (/already exists|already a session|being configured/i.test(msg.description || "")) {
				root._pending = "cancel";
				root._send({ type: "cancel_session" });
				root.message = "Clearing previous attempt...";
				root.messageIsError = false;
				break;
			}

			root._pending = "";
			root.busy = false;
			root.message = root._humanError(msg);
			root.messageIsError = true;
			break;

		case "disconnected":
			root.connected = false;
			root.busy = false;
			root.message = "Lost connection to greetd";
			root.messageIsError = true;
			break;
		}
	}

	Process {
		id: proc

		command: ["python3", Quickshell.shellDir + "/greetd-ipc.py"]
		running: true
		stdinEnabled: true

		stdout: SplitParser {
			onRead: line => {
				const trimmed = line.trim();
				if (trimmed.length === 0)
					return;
				try {
					root._handle(JSON.parse(trimmed));
				} catch (e) {
					console.warn("greetd: unparseable line:", trimmed, e);
				}
			}
		}

		stderr: SplitParser {
			onRead: line => console.warn("greetd-ipc:", line)
		}
	}
}
