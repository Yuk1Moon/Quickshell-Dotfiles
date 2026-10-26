// Bar.qml

import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.widgets
import qs.config
import qs.components

Scope {
	PanelWindow {
		id: root

		implicitHeight: Settings.bar.height
		color: "transparent"

		anchors {
			top: true
			left: true
			right: true
		}

		margins {
			top: Theme.margins
			right: Theme.margins
			left: Theme.margins
		}

		BarContainer {
			anchors.fill: parent

			// Left Section
			RowLayout {
				id: leftSection

				anchors {
					left: parent.left
					verticalCenter: parent.verticalCenter
				}

				spacing: Theme.spacing

				// Elements
				AppLauncherButton {}
				WorkspacesWidget {}
				MediaWidget {}
			}

			// Center Section
			RowLayout {
				id: centerSection

				anchors {
					centerIn: parent
				}

				spacing: Theme.spacing
				
				// Elements
				WindowsWidget {}

				ClockWidget {}
			}

			// Right Section 
			RowLayout {
				id: rightSection

				anchors {
					right: parent.right
					verticalCenter: parent.verticalCenter
				}

				spacing: Theme.spacing

				//Elements
				TrayWidget {}

				NetworkWidget {}

				VolumeWidget {}

				BatteryWidget {}

				NotificationCenterButton {}
			}
		}	
	}
}