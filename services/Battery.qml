// Battery.qml

pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

import qs.config

Singleton {
    id: root

    // display device - Dispositivo Compuesto
    readonly property UPowerDevice device: UPower.displayDevice

    // Battery Availability
    readonly property bool available: device.ready
        && device.isPresent
        && device.isLaptopBattery

    // Quickshell normalizes UPower's percentage to the 0.0 - 1.0 range.
    // Expose 0 - 100 here so thresholds and presentation use real percentages.
    readonly property real percent: device.percentage * 100

    // Current UPower state
    readonly property var state: device.state

    // Flags
    readonly property bool charging: state === UPowerDeviceState.Charging
        || state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged

    // Plugged in but holding (e.g. a charge limit): counted in `charging`
    // above, told apart here for places that spell the state out.
    readonly property bool pending: state === UPowerDeviceState.PendingCharge

    // Watts flowing in or out; 0 while holding or when UPower doesn't know.
    readonly property real rate: device.changeRate

    // Battery Threshold
    readonly property int lowThreshold: Settings.battery.lowThreshold
    readonly property bool low: !charging && !full && percent <= lowThreshold

    // Time to Charge (empty or fill).
    readonly property real timeToEmpty: device.timeToEmpty
    readonly property real timeToFull: device.timeToFull

    // "2 h 15 min", "45 min", "3 h"
    function duration(seconds) {
        const minutes = Math.round(seconds / 60)
        const hours = Math.floor(minutes / 60)

        if (hours === 0) return (minutes % 60) + " min"
        return minutes % 60 === 0 ? hours + " h" : hours + " h " + (minutes % 60) + " min"
    }

    // Warning toasts on the way down: one at lowThreshold, and a critical one
    // at criticalThreshold that stays on screen until closed. Each goes out
    // once per discharge; plugging in takes back the one still showing and
    // starts over.
    //
    // 0 none, 1 low, 2 critical.
    readonly property int warningLevel: !available || charging || full ? 0
        : percent <= Settings.battery.criticalThreshold ? 2
        : percent <= lowThreshold ? 1
        : 0

    // How far down this discharge has been warned about. Not reset when the
    // level wobbles back over a threshold without charging (UPower's estimate
    // does that), or it would warn again a minute later. Kept across live
    // reloads, which would otherwise warn again on every config edit.
    PersistentProperties {
        id: warned

        reloadableId: "batteryWarnings"

        property int level: 0

        onLoaded: {
            root.warningsLoaded = true
            root.checkWarnings()
        }
    }

    // Nothing is checked until `warned` has its level back from before the
    // reload: until then it reads 0, and anything low would warn again.
    property bool warningsLoaded: false

    // Charging or full, as far as warnings go. Watched on its own: right
    // after starting, UPower isn't ready yet and the level reads 0 either
    // way, so plugging in wouldn't move warningLevel.
    readonly property bool pluggedIn: available && (charging || full)

    // Deferred: UPower's properties come in one by one, and a battery that
    // shows up halfway would read as a level it never had.
    onWarningLevelChanged: Qt.callLater(root.checkWarnings)
    onPluggedInChanged: Qt.callLater(root.checkWarnings)

    // The history is read back from disk a moment after starting. A warning
    // saved in it from before a restart, with the charger plugged in since,
    // can only be taken back once it's there. Deferred: `restored` turns on
    // midway through restore(), which still adds the notifications carried
    // over a reload after that, and would put back one taken back here.
    Connections {
        target: Notifications

        function onRestoredChanged() {
            Qt.callLater(root.checkWarnings)
        }
    }

    function checkWarnings() {
        if (!root.warningsLoaded) return

        const level = root.warningLevel

        if (root.pluggedIn) {
            warned.level = 0
            Notifications.clearWarning("battery")
            return
        }

        if (level <= warned.level) return
        warned.level = level

        const left = Math.round(root.percent) + "%"
            + (root.timeToEmpty > 0 ? " · " + root.duration(root.timeToEmpty) + " left" : "")

        // Upright batteries, like the bar's: the one it shows at 20%, and the
        // alert one it shows at the critical level.
        if (level === 2) {
            Notifications.warn("battery", "Battery very low", left + " · Plug in now", "battery_alert", true)
        } else {
            Notifications.warn("battery", "Battery low", left, "battery_2_bar", false)
        }
    }
}
