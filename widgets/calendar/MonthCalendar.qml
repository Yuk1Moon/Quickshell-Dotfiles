// MonthCalendar.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components

ColumnLayout {
    id: root

    readonly property var locale: Qt.locale(Settings.calendar.locale)

    // Month on screen, 0-11. Starts on the current one; reset() brings it back.
    property int month: Time.now.getMonth()
    property int year: Time.now.getFullYear()

    readonly property bool showingCurrent: root.month === Time.now.getMonth()
        && root.year === Time.now.getFullYear()

    function reset() {
        root.month = Time.now.getMonth()
        root.year = Time.now.getFullYear()
    }

    function shift(delta) {
        const first = new Date(root.year, root.month + delta, 1)
        root.month = first.getMonth()
        root.year = first.getFullYear()
    }

    // Some locales give month and day names in lowercase ("septiembre").
    function capitalize(text) {
        return text.charAt(0).toUpperCase() + text.slice(1)
    }

    // "September 2026" for the month on screen, `delta` months away.
    function monthLabel(delta) {
        const first = new Date(root.year, root.month + delta, 1)
        return root.capitalize(root.locale.standaloneMonthName(first.getMonth())) + " " + first.getFullYear()
    }

    spacing: Theme.paddings

    // Header: month chip (click = back to today), today shortcut, arrows
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing

        Rectangle {
            implicitWidth: title.implicitWidth + Theme.paddings * 3
            implicitHeight: 28
            radius: height / 2

            color: Theme.colors.bg

            Text {
                id: title

                anchors.centerIn: parent

                text: root.monthLabel(0)
                color: Theme.colors.fg

                font.family: Theme.font.family
                font.pixelSize: Theme.font.medium
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent

                enabled: !root.showingCurrent
                cursorShape: Qt.PointingHandCursor

                onClicked: root.reset()
            }
        }

        Item {
            Layout.fillWidth: true
        }

        IconButton {
            id: today

            visible: !root.showingCurrent

            size: 28
            icon: "today"

            onClicked: root.reset()

            // Hidden with the button: clicking it lands on the current month.
            Tooltip {
                target: today
                below: today
                active: !root.showingCurrent

                icon: today.icon
                title: "Today"
                body: root.capitalize(Time.now.toLocaleDateString(root.locale, "dddd, d MMMM"))
            }
        }

        IconButton {
            id: previous

            size: 28
            baseColor: Theme.colors.bg
            icon: "chevron_left"

            onClicked: root.shift(-1)

            Tooltip {
                target: previous
                below: previous

                icon: previous.icon
                title: "Previous month"
                body: root.monthLabel(-1)
            }
        }

        IconButton {
            id: next

            size: 28
            baseColor: Theme.colors.bg
            icon: "chevron_right"

            onClicked: root.shift(1)

            Tooltip {
                target: next
                below: next

                icon: next.icon
                title: "Next month"
                body: root.monthLabel(1)
            }
        }
    }

    DayOfWeekRow {
        Layout.fillWidth: true

        locale: root.locale
        padding: 0
        spacing: 0

        // Two letters ("Su Mo Tu"): the narrow names repeat letters (T/T,
        // S/S) and some locales' short ones carry a trailing dot.
        delegate: Text {
            required property string shortName

            text: root.capitalize(shortName.replace(".", "").slice(0, 2))
            color: Theme.colors.fg
            horizontalAlignment: Text.AlignHCenter

            font.family: Theme.font.family
            font.pixelSize: Theme.font.small
            font.weight: Font.Medium
        }
    }

    MonthGrid {
        id: grid

        Layout.fillWidth: true
        Layout.fillHeight: true

        month: root.month
        year: root.year
        locale: root.locale

        padding: 0
        spacing: 0

        // Compares the day/month/year roles against Time.now instead of using
        // the `today` role: that one is computed once per month change, so it
        // would go stale across midnight while the shell keeps running. The
        // `date` role is skipped too — QDate -> JS Date conversion can land on
        // the previous day in timezones west of UTC.
        delegate: Item {
            id: cell

            required property int day
            required property int month
            required property int year

            readonly property bool inMonth: cell.month === grid.month
            readonly property bool isToday: cell.day === Time.now.getDate()
                && cell.month === Time.now.getMonth()
                && cell.year === Time.now.getFullYear()

            Rectangle {
                anchors.centerIn: parent

                width: Math.min(cell.width, cell.height) - Theme.spacing
                height: width
                radius: width / 2

                color: cell.isToday ? Theme.colors.accent : "transparent"
            }

            Text {
                anchors.centerIn: parent

                text: cell.day
                color: cell.isToday
                    ? Theme.colors.onAccent
                    : cell.inMonth ? Theme.colors.fg : Qt.alpha(Theme.colors.muted, 0.6)

                font.family: Theme.font.family
                font.pixelSize: Theme.font.size
                font.weight: cell.isToday ? Font.DemiBold : Font.Normal
            }
        }

        // Scroll changes month; clicks pass through.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton

            onWheel: (wheel) => root.shift(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
