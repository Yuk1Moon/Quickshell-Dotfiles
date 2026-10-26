// Settings.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	// Bar
	readonly property QtObject bar: QtObject {
		readonly property int height: 42
	}

	// App Launcher
	readonly property QtObject appLauncher: QtObject {
		readonly property int width: 420
		readonly property int height: 480
		readonly property int padding: 14 // Inside the panel, same as the sidebar's
		readonly property int spacing: 12 // Between search, list and footer
	}

	// Services
	readonly property QtObject battery: QtObject {
		// Percent. Each one warns with a toast on the way down; the critical
		// one stays on screen until closed or the charger goes in.
		readonly property int lowThreshold: 20
		readonly property int criticalThreshold: 10
	}

	readonly property QtObject network: QtObject {
		readonly property int pollInterval: 3000 // ms
	}

	readonly property QtObject audio: QtObject {
		readonly property int step: 5 // Percent per scroll notch
	}

	readonly property QtObject windows: QtObject {
		// Fixed number of slots in the bar, not a maximum: the widget sits in
		// the centered section, so a pill that grew and shrank would shove the
		// clock sideways every time a window opened or closed.
		readonly property int limit: 5

		// The list of an app's windows, dropped from its icon.
		readonly property int menuMinWidth: 200
		readonly property int menuMaxWidth: 340 // Longer titles elide
	}

	readonly property QtObject brightness: QtObject {
		// A hybrid-GPU laptop exposes one backlight per GPU and only one of
		// them drives the panel, so the device is named instead of guessed.
		// Same one the Hyprland media keys target.
		readonly property string device: "intel_backlight"
		readonly property int step: 5 // Percent per scroll notch
		readonly property int minimum: 2 // Device units, never a fully dark panel
	}

	readonly property QtObject notifications: QtObject {
		readonly property int width: 320
		readonly property int timeout: 5000 // ms, used when the sender doesn't set one
		readonly property int maxHistory: 50
	}

	readonly property QtObject tooltip: QtObject {
		readonly property int delay: 500 // ms of hovering before the first one shows
		readonly property int grace: 300 // ms after one hides during which the next shows at once
		readonly property int minWidth: 180
		readonly property int maxWidth: 300 // Longer titles elide, longer details wrap to two lines
	}

	readonly property QtObject tray: QtObject {
		readonly property int menuMinWidth: 180
		readonly property int menuMaxWidth: 300 // Longer entries elide
	}

	readonly property QtObject media: QtObject {
		readonly property int maxWidth: 220 // Title and artist in the bar; longer ones elide
	}

	readonly property QtObject osd: QtObject {
		readonly property int width: 300
		readonly property int timeout: 1500 // ms after the last key press
	}

	readonly property QtObject calendar: QtObject {
		// Month/day names and the first day of the week: en_US starts on
		// Sunday, en_GB on Monday. Set explicitly because the system locale
		// here is C.
		readonly property string locale: "en_US"
	}

	readonly property QtObject notificationCenter: QtObject {
		readonly property int width: 360
		readonly property real bottomRatio: 0.34 // Share of the height taken by the lower section
		readonly property int padding: 14 // Inside each popup
		readonly property int spacing: 12 // Between the blocks of a popup
	}
}
