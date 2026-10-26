/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    property var backend

    Style {
        id: st
    }

    spacing: 12

    PC3.Label {
        visible: root.backend ? root.backend.powerProfilesAvailable : false
        text: i18n("Power profile")
        font.pointSize: st.fontSmall
        color: st.textMuted
    }

    PowerSelector {
        Layout.fillWidth: true
        backend: root.backend
    }

    RowLayout {
        visible: root.backend ? root.backend.hasBattery : false
        Layout.fillWidth: true
        spacing: 8

        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: root.backend && root.backend.charging ? "battery-good-charging-symbolic" : "battery-good-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            Layout.fillWidth: true
            text: root.backend && root.backend.charging ? i18n("Charging") : i18n("Discharging")
            color: Kirigami.Theme.textColor
        }

        PC3.Label {
            text: (root.backend ? root.backend.batteryPercent : 0) + "%"
            color: st.textMuted
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
