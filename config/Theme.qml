// Theme.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	// Palletes
	readonly property QtObject palette: QtObject {
		// Purple colors
		readonly property color shadow: "#39314A"
		readonly property color slate: "#3a3751"
		readonly property color haze: "#655F8B"
		readonly property color mist: "#F4F3F7"
		readonly property color iris: "#6E46B9"

		// Rose colors
		readonly property color pink: "#FF83A2"
		readonly property color crimson: "#BA3971"
		readonly property color clay: "#C54F5A"
		readonly property color rose: "#BA5170"
		readonly property color ember: "#D95045"

		// Black colors
		readonly property color night: "#1a191f"
		readonly property color void_: "#211330" // "void" is a reserved word
		readonly property color soot: "#25201F"
		readonly property color iron: "#3A3B40"

		// States
		readonly property color coral: "#E56272"
		readonly property color amber: "#F9DB7A"
		readonly property color sage: "#70C28B"
	}

	// Roles

	readonly property QtObject colors: QtObject {
		
		// Surfaces	
		readonly property color bg: Qt.alpha(root.palette.soot, 0.9) // Background layer
		readonly property color surface: Qt.alpha(root.palette.night, 0.8)// Popups over background
		readonly property color surfaceMid: Qt.alpha(root.palette.slate, 0.7)
		readonly property color surfaceHigh: root.palette.iron // Floating panel

		// Text
		readonly property color fg: root.palette.mist // Main color
		readonly property color muted: root.palette.haze // Secondary color
		readonly property color onAccent: root.palette.night // Accent color over accent surface

		// Identity
		readonly property color accent: root.palette.clay /// Identity
		readonly property color accentDark: root.palette.crimson // Varia

		// Interaction states
		readonly property color hover: Qt.alpha(root.palette.haze, 0.25) // Hover bg
		readonly property color selected: Qt.alpha(root.palette.crimson, 0.8) // Activated Item bg
		readonly property color container: Qt.alpha(root.palette.iron, 0.3) // Soft accent fill (chips, highlighted cards)

		// Semantic States
		readonly property color error: root.palette.coral // Critical Error
		readonly property color warn: root.palette.amber // Advertising
		readonly property color ok: root.palette.sage // Positive
		readonly property color scrim: Qt.alpha(root.palette.night, 0.6) // Darken
	} 

	readonly property QtObject gradient: QtObject {
		readonly property color top: root.palette.clay
		readonly property color mid: root.palette.haze
		readonly property color bottom: root.palette.iris
	}

	// Fonts
	readonly property QtObject font: QtObject {
		readonly property string family: "Maple Mono NF"
		readonly property string icons: "Material Symbols Rounded"
		readonly property int size: 14
		readonly property int small: 12
		readonly property int medium: 16
		readonly property int large: 18
	}

	// Geometry
	readonly property int edges: 6
	readonly property int radius: 8
	readonly property int radiusCard: 12 // Cards inside a panel
	readonly property int radiusPanel: 16 // Large floating panels (sidebar)

	// Paddings
	readonly property int pHorizontal: 8
	readonly property int pVertical: 6

	readonly property int paddings: 8

	// Margins
	readonly property int mHorizontal: 10
	readonly property int mVertical: 4
	
	readonly property int margins: 8

	// Borders
	readonly property int border: 2

	// Spacing
	readonly property int spacing: 4
}

