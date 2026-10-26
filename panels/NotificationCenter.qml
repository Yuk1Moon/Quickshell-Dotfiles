// NotificationCenter.qml

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components
import qs.widgets
import qs.widgets.bluetooth
import qs.widgets.calendar
import qs.widgets.network
import qs.widgets.notifications
import qs.widgets.quickSettings

Scope {
    PanelWindow {
        id: root

        visible: Notifications.centerOpen

        color: "transparent"

        // Purely a floating overlay — don't reserve screen space like the bar does.
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            right: true
            bottom: true
        }

        // Same edges as tiled windows: Theme.margins matches Hyprland's
        // gaps_out, so the panel lines up with the bar and with any window
        // next to it.
        margins {
            // Start below the bar, not under it: the bar's right section
            // (including the button that opens this panel) lives in the same
            // screen region, and whichever layer surface is on top eats the
            // clicks meant for the other.
            top: Theme.margins + Settings.bar.height + Theme.margins
            right: Theme.margins
            bottom: Theme.margins
        }

        implicitWidth: Settings.notificationCenter.width

        // Keyboard only while a Wi-Fi password or a notification reply is
        // being typed: the rest of the time the panel shouldn't take focus
        // away from the window behind.
        WlrLayershell.keyboardFocus: wifi.typing || Notifications.replyingTo !== null
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Every time the panel opens, the calendar starts on the current month.
        onVisibleChanged: if (visible) calendar.reset()

        // Two separate popups, same gap as between windows (gaps_in)
        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.margins

            // Upper popup: clock + power button, quick toggles, notifications
            PopupContainer {
                Layout.fillWidth: true
                Layout.fillHeight: true

                padding: Settings.notificationCenter.padding
                radius: Theme.radiusPanel

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Settings.notificationCenter.spacing

                    // Header: clock, then round actions on the right
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.spacing

                        spacing: Theme.spacing

                        Text {
                            Layout.fillWidth: true

                            text: Time.time
                            color: Theme.colors.fg

                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.large
                            font.weight: Font.Medium
                        }

                        EmptySlot {}
                        EmptySlot {}

                        PowerButton {}
                    }

                    QuickToggles {
                        Layout.fillWidth: true
                    }

                    CardContainer {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Theme.paddings

                            ChipTabs {
                                id: tabs

                                Layout.alignment: Qt.AlignHCenter

                                tabs: [
                                    { icon: "notifications", label: "Notifications" },
                                    { icon: "wifi", label: "Wi-Fi" },
                                    { icon: "bluetooth", label: "Bluetooth" }
                                ]
                                placeholders: 1
                            }

                            StackLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                currentIndex: tabs.current

                                NotificationHistory {}

                                WifiPanel {
                                    id: wifi

                                    active: root.visible && tabs.current === 1
                                }

                                BluetoothPanel {
                                    active: root.visible && tabs.current === 2
                                }
                            }
                        }
                    }
                }
            }

            // Lower popup: calendar
            PopupContainer {
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * Settings.notificationCenter.bottomRatio

                padding: Settings.notificationCenter.padding
                radius: Theme.radiusPanel

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.paddings

                    // Side rail: calendar is the only view so far, with an
                    // empty slot where a second one would go.
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 64

                        spacing: Theme.spacing

                        Item {
                            Layout.fillHeight: true
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter

                            implicitWidth: 48
                            implicitHeight: 28
                            radius: height / 2

                            color: Theme.colors.container

                            Text {
                                anchors.centerIn: parent

                                text: "calendar_month"
                                color: Theme.colors.fg

                                font.family: Theme.font.icons
                                font.pixelSize: Theme.font.medium
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter

                            text: "Calendar"
                            color: Theme.colors.fg

                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.small
                        }

                        EmptySlot {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: Theme.paddings

                            size: 28
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    MonthCalendar {
                        id: calendar

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
