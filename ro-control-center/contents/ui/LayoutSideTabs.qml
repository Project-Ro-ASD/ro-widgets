/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Item {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend
    property string currentTab: "ag"

    implicitWidth: 420
    implicitHeight: content.implicitHeight

    Style {
        id: st
    }

    readonly property var tabList: [
        { id: "ag", icon: "network-wireless-symbolic", label: i18n("Network") },
        { id: "bluetooth", icon: "bluetooth-disabled-symbolic", label: i18n("Bluetooth") },
        { id: "ses", icon: "audio-volume-high-symbolic", label: i18n("Audio") },
        { id: "ekran", icon: "display-brightness-symbolic", label: i18n("Display") },
        { id: "guc", icon: "power-profile-balanced-symbolic", label: i18n("Power") }
    ]

    function tabIndex(id) {
        for (let i = 0; i < tabList.length; ++i) {
            if (tabList[i].id === id) {
                return i
            }
        }
        return 0
    }

    component PillToggle: Rectangle {
        id: pill
        property string iconName: ""
        property string labelText: ""
        property string subText: ""
        property bool active: false

        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: st.radiusCard
        color: active ? st.accent : (pillMouse.containsMouse ? st.hover : st.glassRaised)
        border.width: active ? 0 : st.borderWidth
        border.color: st.glassBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Kirigami.Icon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: pill.iconName
                isMask: true
                color: pill.active ? st.onAccent : Kirigami.Theme.textColor
            }

            PC3.Label {
                Layout.fillWidth: true
                text: pill.subText !== "" ? (pill.labelText + " · " + pill.subText) : pill.labelText
                color: pill.active ? st.onAccent : Kirigami.Theme.textColor
                font.pointSize: st.fontSmall
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: pill.clicked()
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: RoTokens.spaceMd

        RowLayout {
            Layout.fillWidth: true

            PC3.Label {
                Layout.fillWidth: true
                text: i18n("Quick Settings")
                color: Kirigami.Theme.textColor
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            spacing: 8

            ColumnLayout {
                Layout.preferredWidth: 48
                Layout.fillHeight: true
                spacing: 6

                TabColumn {
                    Layout.alignment: Qt.AlignHCenter
                    tabs: root.tabList
                    current: root.currentTab
                    onSelected: id => root.currentTab = id
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    id: dndButton
                    readonly property bool dndActive: root.backend ? root.backend.dndEnabled : false

                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    Layout.alignment: Qt.AlignHCenter
                    radius: st.radiusCard
                    color: dndActive ? st.accent : (dndMouse.containsMouse ? st.hover : st.glassRaised)
                    border.width: dndActive ? 0 : st.borderWidth
                    border.color: st.glassBorder

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "notifications-disabled-symbolic"
                        isMask: true
                        color: dndButton.dndActive ? st.onAccent : Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.backend) {
                                root.backend.setDndEnabled(!root.backend.dndEnabled)
                            }
                        }
                    }

                    PC3.ToolTip.text: i18n("Do Not Disturb")
                    PC3.ToolTip.visible: dndMouse.containsMouse
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: st.glass
                border.width: st.borderWidth
                border.color: st.glassBorder
                radius: st.radiusCard

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    currentIndex: root.tabIndex(root.currentTab)

                    NetworkPage {
                        backend: root.backend
                    }

                    BluetoothPage {
                        backend: root.backend
                    }

                    AudioPage {
                        backend: root.backend
                    }

                    DisplayPage {
                        backend: root.backend
                    }

                    PowerPage {
                        backend: root.backend
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PillToggle {
                iconName: "night-light-symbolic"
                labelText: i18n("Night Light")
                subText: root.backend && root.backend.nightLightActive ? i18n("On") : i18n("Off")
                active: root.backend ? root.backend.nightLightActive : false
                onClicked: {
                    if (root.backend) {
                        root.backend.toggleNightLight()
                    }
                }
            }

            PillToggle {
                iconName: "weather-clear-night-symbolic"
                labelText: i18n("Dark Theme")
                subText: root.backend && root.backend.darkMode ? i18n("Dark") : i18n("Light")
                active: root.backend ? root.backend.darkMode : false
                onClicked: {
                    if (root.backend) {
                        root.backend.setDarkMode(!root.backend.darkMode)
                    }
                }
            }
        }
    }
}
