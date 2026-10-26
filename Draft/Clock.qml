
import QtQuick

Text {
	id: clock
	color: "#cdd6f4"

	Timer {
		interval: 1000
		running: true
		repeat: true
		triggeredOnStart: true

		onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
	}
}
