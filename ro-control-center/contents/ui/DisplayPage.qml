/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

ColumnLayout {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend

    Style {
        id: st
    }

    spacing: 12

    SliderRow {
        visible: root.backend ? root.backend.brightnessAvailable : false
        Layout.fillWidth: true
        iconName: "display-brightness-symbolic"
        value: root.backend ? root.backend.brightness : 0
        onMoved: v => {
            if (root.backend) {
                root.backend.setBrightness(v)
            }
        }
    }

    RowLayout {
        visible: root.backend ? root.backend.nightLightAvailable : true
        Layout.fillWidth: true

        Kirigami.Icon {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: "night-light-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Night Light")
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            enabled: root.backend ? root.backend.nightLightAvailable : false
            checked: root.backend ? root.backend.nightLightActive : false
            onToggled: {
                if (root.backend) {
                    root.backend.toggleNightLight()
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Icon {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: "weather-clear-night-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Dark Theme")
            color: Kirigami.Theme.textColor
        }

        PC3.Switch {
            checked: root.backend ? root.backend.darkMode : false
            onToggled: {
                if (root.backend) {
                    root.backend.setDarkMode(checked)
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
