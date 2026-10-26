// Bar.qml

import Quickshell
import QtQuick

import qs.widgets
import qs.config

Scope {
	PanelWindow {
		id: root

		implicitHeight: 42

		// Background Color
		color: Theme.colors.bg

		anchors {
			top: true
			left: true
			right: true
		}

		Row {
			anchors.centerIn: parent
			

			ClockWidget {
			}
			
		}
	}
}