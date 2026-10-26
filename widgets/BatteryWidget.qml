// BatteryWidget.qml

import QtQuick
import QtQuick.Layouts

import qs.services
import qs.config
import qs.components

PillContainer {
    id: pill

    RowLayout {
        visible: Battery.available

        id: root
        anchors.verticalCenter: parent.verticalCenter

        spacing: Theme.spacing

        // Color Selection
        readonly property color statusColor: {
            if (Battery.charging || Battery.full) return Theme.colors.ok
            if (Battery.low) return Theme.colors.error
            if (Battery.percent <= 40) return Theme.colors.warn
            return Theme.colors.fg
        }

        // Icon
        readonly property string iconName: {
            if (Battery.charging) return "battery_charging_full"
            if (Battery.full) return "battery_full"
            if (Battery.percent <= Settings.battery.criticalThreshold) return "battery_alert"

            // Clamp unexpected UPower values before selecting one of the six bars.
            const percent = Math.max(0, Math.min(100, Battery.percent))
            const bars = Math.ceil(percent / 100 * 6)
            return bars <= 0 ? "battery_0_bar" : "battery_" + bars + "_bar"
        }

        Text {
            id: icon

            text: root.iconName
            color: root.statusColor

            font.family: Theme.font.icons
            font.pixelSize: Theme.font.medium
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: label
            
            text: Math.round(Battery.percent) + "%"
            color: root.statusColor

            font.family: Theme.font.family
            font.pixelSize: Theme.font.size
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Tooltip {
        target: pill
        active: Battery.available

        icon: root.iconName
        alert: Battery.low

        title: "Battery"
        meta: Math.round(Battery.percent) + "%"
        body: {
            if (Battery.full) return "Fully charged"
            if (Battery.pending) return "Plugged in, not charging"
            if (Battery.charging) {
                return Battery.timeToFull > 0 ? "Charging · full in " + Battery.duration(Battery.timeToFull) : "Charging"
            }

            const left = Battery.timeToEmpty > 0 ? Battery.duration(Battery.timeToEmpty) + " left" : "On battery"
            return Battery.rate > 0 ? left + " · " + Battery.rate.toFixed(1) + " W" : left
        }

        progress: Battery.percent / 100
        progressColor: Battery.low ? Theme.colors.error
            : Battery.charging || Battery.full ? Theme.colors.ok
            : Theme.colors.accent
    }
}
