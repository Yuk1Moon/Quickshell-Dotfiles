// ClockWidget.qml

import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components

PillContainer {
	id: pill

	RowLayout {
		id: root
		anchors.verticalCenter: parent.verticalCenter

		spacing: Theme.spacing

		Text { 
			id: time

			text: Time.time
			color: Theme.colors.fg

			font.family: Theme.font.family
			font.pixelSize: Theme.font.size
		}

		// Separator
		VerticalSeparator { 
			referenceHeight: time.height
		}

		Text {
			id: date
			
			text: Time.date
			color: Theme.colors.fg

			font.family: Theme.font.family
			font.pixelSize: Theme.font.size
		}
	}

	Tooltip {
		target: pill

		readonly property var locale: Qt.locale(Settings.calendar.locale)

		icon: "calendar_today"
		title: Time.now.toLocaleDateString(locale, "dddd")
		meta: "Week " + Time.week
		body: Time.now.toLocaleDateString(locale, "d MMMM yyyy")
	}
}
