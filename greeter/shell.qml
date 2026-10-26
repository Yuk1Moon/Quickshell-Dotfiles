// shell.qml — greetd greeter

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
	Variants {
		// One surface per monitor; only the focused one takes input.
		model: Quickshell.screens

		PanelWindow {
			id: win

			required property var modelData
			screen: modelData

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
			WlrLayershell.namespace: "greeter"

			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}

			color: Theme.colors.bg

			// Installed copy of the wallpaper. It cannot live in /home: the greeter
			// user cannot traverse a drwx------ home. QS_GREETER_WALLPAPER lets
			// test-nested.sh point straight at the real one while iterating.
			readonly property string wallpaperPath: {
				const override = Quickshell.env("QS_GREETER_WALLPAPER");
				return (override === undefined || override === null || override === "")
					? "/etc/greetd/wallpaper.png"
					: String(override);
			}

			// Answer typed before greetd got around to asking for it.
			property var pendingAnswer: null

			function submit() {
				if (Greetd.busy) {
					// A prompt is already on the table; answer it directly.
					if (Greetd.awaitingPrompt)
						Greetd.respond(password.text);
					password.text = "";
					return;
				}
				const user = userField.text.trim();
				if (user === "") {
					userField.forceActiveFocus();
					return;
				}

				win.applySession();
				win.pendingAnswer = password.text;
				password.text = "";
				Greetd.login(user);
			}

			function applySession() {
				// No session picker: the helper already drops entries whose TryExec
				// binary is missing, so whatever survives first is the one that runs.
				// If nothing survived, Greetd's own default (start-hyprland) stands.
				const s = Greetd.sessions[0];
				if (!s)
					return;
				Greetd.sessionCmd = s.cmd;
				Greetd.sessionDesktop = s.xdgDesktop !== "" ? s.xdgDesktop : s.name;
				Greetd.sessionWayland = s.wayland;
			}

			Connections {
				target: Greetd

				function onAwaitingPromptChanged() {
					if (!Greetd.awaitingPrompt)
						return;

					if (win.pendingAnswer !== null) {
						const answer = win.pendingAnswer;
						win.pendingAnswer = null;
						Greetd.respond(answer);
					} else {
						// greetd asked something we have no answer queued for,
						// such as a second factor. Let the user type it.
						password.forceActiveFocus();
					}
				}

				function onSessionStarted() {
					// greetd launches the session only once the greeter is gone.
					Qt.quit();
				}
			}

			// Fallback, and what shows through if no wallpaper is installed.
			Rectangle {
				anchors.fill: parent

				gradient: Gradient {
					GradientStop { position: 0.0; color: Qt.darker(Theme.gradient.top, 2.4) }
					GradientStop { position: 0.55; color: Theme.colors.bg }
					GradientStop { position: 1.0; color: Qt.darker(Theme.gradient.bottom, 2.2) }
				}
			}

			Image {
				id: wallpaper

				anchors.fill: parent
				source: "file://" + win.wallpaperPath
				fillMode: Image.PreserveAspectCrop // matches hyprpaper's fit_mode = cover
				asynchronous: true
				cache: false
				visible: status === Image.Ready

				onStatusChanged: {
					if (status === Image.Error)
						console.warn("greeter: could not load wallpaper:", win.wallpaperPath);
				}
			}

			// Scrim. Without it the clock and the card fight the wallpaper for
			// contrast, and a bright image makes the password field unreadable.
			Rectangle {
				anchors.fill: parent
				visible: wallpaper.visible

				gradient: Gradient {
					GradientStop { position: 0.0; color: Qt.alpha(Theme.colors.bg, 0.55) }
					GradientStop { position: 1.0; color: Qt.alpha(Theme.colors.bg, 0.8) }
				}
			}

			// Clock
			ColumnLayout {
				anchors {
					horizontalCenter: parent.horizontalCenter
					top: parent.top
					topMargin: parent.height * 0.12
				}

				spacing: Theme.spacing

				Text {
					Layout.alignment: Qt.AlignHCenter
					text: Time.clock
					color: Theme.colors.fg
					font.family: Theme.font.family
					font.pixelSize: Theme.font.huge
					font.weight: Font.Light
				}

				Text {
					Layout.alignment: Qt.AlignHCenter
					text: Time.date
					color: Theme.colors.muted
					font.family: Theme.font.family
					font.pixelSize: Theme.font.medium
				}
			}

			// Login card
			Rectangle {
				id: card

				anchors.centerIn: parent
				anchors.verticalCenterOffset: parent.height * 0.12

				implicitWidth: 380
				implicitHeight: layout.implicitHeight + Theme.paddings * 4

				radius: Theme.radius
				color: Theme.colors.surface
				border.width: 1
				border.color: Qt.alpha(Theme.colors.muted, 0.35)

				ColumnLayout {
					id: layout

					anchors.centerIn: parent
					width: parent.width - Theme.paddings * 4
					spacing: Theme.paddings * 1.5

					// User
					RowLayout {
						Layout.fillWidth: true
						spacing: Theme.paddings

						Text {
							text: "person"
							color: Theme.colors.muted
							font.family: Theme.font.icons
							font.pixelSize: Theme.font.large
						}

						TextField {
							id: userField

							Layout.fillWidth: true
							focus: true
							enabled: !Greetd.busy

							placeholderText: "Username"
							placeholderTextColor: Theme.colors.muted

							color: Theme.colors.fg
							font.family: Theme.font.family
							font.pixelSize: Theme.font.size

							leftPadding: Theme.pHorizontal
							rightPadding: Theme.pHorizontal

							background: Rectangle {
								implicitHeight: 36
								radius: Theme.edges
								color: Theme.colors.surfaceHigh
								border.width: userField.activeFocus ? 1 : 0
								border.color: Theme.colors.accent
							}

							// Enter moves on rather than submitting, so the password
							// is not sent before it has been typed.
							onAccepted: password.forceActiveFocus()
						}
					}

					// Password / prompt answer
					RowLayout {
						Layout.fillWidth: true
						spacing: Theme.paddings

						Text {
							text: "password"
							color: Theme.colors.muted
							font.family: Theme.font.icons
							font.pixelSize: Theme.font.large
						}

						TextField {
							id: password

							Layout.fillWidth: true
							enabled: !Greetd.busy || Greetd.awaitingPrompt

							echoMode: Greetd.awaitingPrompt && !Greetd.promptSecret
								? TextInput.Normal
								: TextInput.Password

							placeholderText: Greetd.awaitingPrompt && Greetd.prompt !== ""
								? Greetd.prompt
								: "Password"
							placeholderTextColor: Theme.colors.muted

							color: Theme.colors.fg
							font.family: Theme.font.family
							font.pixelSize: Theme.font.size

							leftPadding: Theme.pHorizontal
							rightPadding: Theme.pHorizontal

							background: Rectangle {
								implicitHeight: 36
								radius: Theme.edges
								color: Theme.colors.surfaceHigh
								border.width: password.activeFocus ? 1 : 0
								border.color: Theme.colors.accent
							}

							onAccepted: win.submit()
						}
					}

					// Status line
					Text {
						Layout.fillWidth: true
						Layout.preferredHeight: Theme.font.size * 1.4

						text: Greetd.message
						color: Greetd.messageIsError ? Theme.colors.error : Theme.colors.muted
						font.family: Theme.font.family
						font.pixelSize: Theme.font.small
						wrapMode: Text.WordWrap
						horizontalAlignment: Text.AlignHCenter
					}
				}
			}

			// Typing is the only way in, so something must always hold focus.
			Component.onCompleted: userField.forceActiveFocus()

			Connections {
				target: Greetd

				function onConnectedChanged() {
					if (Greetd.connected)
						userField.forceActiveFocus();
				}

				// A rejected login lands back here. The username is almost never
				// the part that was wrong, so keep it and retry the password.
				function onMessageIsErrorChanged() {
					if (Greetd.messageIsError && !Greetd.busy)
						password.forceActiveFocus();
				}
			}
		}
	}
}
