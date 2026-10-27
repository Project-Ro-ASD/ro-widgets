/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Rectangle {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend

    Style {
        id: st
    }

    visible: backend ? backend.powerProfilesAvailable : false
    implicitWidth: 260
    implicitHeight: 36
    radius: st.radiusCard
    color: st.glassRaised
    border.width: st.borderWidth
    border.color: st.glassBorder

    function profileLabel(id) {
        if (id === "power-saver") {
            return i18n("Power Save")
        }
        if (id === "balanced") {
            return i18n("Balanced")
        }
        if (id === "performance") {
            return i18n("Performance")
        }
        return id
    }

    function profileIcon(id) {
        if (id === "power-saver") {
            return "power-profile-power-saver-symbolic"
        }
        if (id === "performance") {
            return "power-profile-performance-symbolic"
        }
        return "power-profile-balanced-symbolic"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 2

        Repeater {
            model: root.backend && root.backend.powerProfiles && root.backend.powerProfiles.length > 0
                ? root.backend.powerProfiles
                : ["power-saver", "balanced", "performance"]

            delegate: Rectangle {
                id: seg
                required property string modelData
                readonly property bool current: root.backend ? root.backend.activeProfile === modelData : false

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: st.radiusItem
                color: current ? st.accent : (segMouse.containsMouse ? st.hover : "transparent")

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: root.profileIcon(seg.modelData)
                        isMask: true
                        color: seg.current ? st.onAccent : Kirigami.Theme.textColor
                    }

                    PC3.Label {
                        text: root.profileLabel(seg.modelData)
                        font.pointSize: st.fontSmall
                        color: seg.current ? st.onAccent : Kirigami.Theme.textColor
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.backend) {
                            root.backend.setPowerProfile(seg.modelData)
                        }
                    }
                }
            }
        }
    }
}
