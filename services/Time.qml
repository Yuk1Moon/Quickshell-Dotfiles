// Time.qml

pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	readonly property date now: clock.date

	readonly property string time: Qt.formatDateTime(clock.date, "hh:mm")
	
	readonly property string date: Qt.formatDateTime(clock.date, "ddd d MMM")

	// ISO 8601 week number (weeks start on Monday, week 1 holds the year's
	// first Thursday), whatever day Settings.calendar starts its weeks on.
	readonly property int week: {
		const day = new Date(Date.UTC(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate()))
		day.setUTCDate(day.getUTCDate() + 4 - (day.getUTCDay() || 7)) // That week's Thursday
		const yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1))
		return Math.ceil(((day - yearStart) / 86400000 + 1) / 7)
	}

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}
}
	
