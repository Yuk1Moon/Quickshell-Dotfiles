// Theme.qml
pragma Singleton

import Quickshell
import QtQuick

// Standalone copy of the shell palette: the greeter runs as the `greeter` user,
// which cannot read /home/Yuki, so it cannot import qs.config.
Singleton {
	id: root

	readonly property QtObject palette: QtObject {
		readonly property color night: "#1a191f"
		readonly property color shadow: "#39314A"
		readonly property color slate: "#3a3751"
		readonly property color haze: "#655F8B"
		readonly property color mist: "#F4F3F7"
		readonly property color iris: "#6E46B9"

		readonly property color pink: "#FF83A2"
		readonly property color crimson: "#B03758"
		readonly property color wine: "#B13B60"
		readonly property color rose: "#B44B6F"

		readonly property color coral: "#E56272"
		readonly property color amber: "#F9DB7A"
		readonly property color sage: "#70C28B"
	}

	readonly property QtObject colors: QtObject {
		readonly property color bg: root.palette.night
		readonly property color surface: Qt.alpha(root.palette.shadow, 0.8)
		readonly property color surfaceHigh: root.palette.slate

		readonly property color fg: root.palette.mist
		readonly property color muted: root.palette.haze
		readonly property color onAccent: root.palette.mist

		readonly property color accent: root.palette.wine
		readonly property color accentDark: root.palette.crimson

		readonly property color hover: Qt.alpha(root.palette.haze, 0.25)
		readonly property color selected: Qt.alpha(root.palette.crimson, 0.8)

		readonly property color error: root.palette.coral
		readonly property color warn: root.palette.amber
		readonly property color ok: root.palette.sage
		readonly property color scrim: Qt.alpha(root.palette.night, 0.6)
	}

	readonly property QtObject gradient: QtObject {
		readonly property color top: root.palette.wine
		readonly property color mid: root.palette.haze
		readonly property color bottom: root.palette.iris
	}

	readonly property QtObject font: QtObject {
		readonly property string family: "Inter"
		readonly property string icons: "Material Symbols Rounded"
		readonly property int size: 14
		readonly property int small: 12
		readonly property int medium: 16
		readonly property int large: 18
		readonly property int huge: 64
	}

	readonly property int edges: 6
	readonly property int radius: 8

	readonly property int pHorizontal: 8
	readonly property int pVertical: 6
	readonly property int paddings: 8

	readonly property int margins: 8
	readonly property int spacing: 4
	readonly property int border: 2
}
