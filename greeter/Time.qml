// Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	readonly property string clock: Qt.formatDateTime(clockTimer.now, "HH:mm")
	readonly property string date: Qt.formatDateTime(clockTimer.now, "dddd, d MMMM")

	Timer {
		id: clockTimer

		property date now: new Date()

		interval: 1000
		running: true
		repeat: true
		triggeredOnStart: true

		onTriggered: now = new Date()
	}
}
