/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons

Item {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend
    property string currentTab: "genel"

    implicitWidth: 420
    implicitHeight: content.implicitHeight

    Style {
        id: st
    }

    readonly property var tabList: [
        { id: "genel", icon: "view-grid-symbolic", label: i18n("General") },
        { id: "ag", icon: "network-wireless-symbolic", label: i18n("Network") },
        { id: "bluetooth", icon: "bluetooth-disabled-symbolic", label: i18n("Bluetooth") },
        { id: "ses", icon: "audio-volume-high-symbolic", label: i18n("Audio") },
        { id: "ekran", icon: "display-brightness-symbolic", label: i18n("Display") },
        { id: "guc", icon: "power-profile-balanced-symbolic", label: i18n("Power") },
        { id: "pano", icon: "klipper-symbolic", label: i18n("Clipboard") }
    ]

    // Genel sekmesindeki pil özeti: "%64 · 0:52".
    function batterySummary() {
        if (!root.backend || !root.backend.hasBattery) {
            return ""
        }
        const percent = root.backend.batteryPercent + "%"
        if (root.backend.remainingMsec > 0) {
            return percent + " · " + KCoreAddons.Format.formatDuration(root.backend.remainingMsec, KCoreAddons.FormatTypes.HideSeconds)
        }
        return percent
    }

    function tabIndex(id) {
        // Klavye düzeni sekme değil, Genel'deki kartın okundan açılan gizli sayfa.
        if (id === "klavye") {
            return tabList.length
        }
        for (let i = 0; i < tabList.length; ++i) {
            if (tabList[i].id === id) {
                return i
            }
        }
        return 0
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
            Layout.fillHeight: true
            spacing: RoTokens.spaceMd

            TabColumn {
                Layout.alignment: Qt.AlignTop
                tabs: root.tabList
                current: root.currentTab
                onSelected: id => root.currentTab = id
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: st.glassBorder
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.tabIndex(root.currentTab)

                ColumnLayout {
                    spacing: RoTokens.spaceMd

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: RoTokens.spaceSm
                        rowSpacing: RoTokens.spaceSm

                        Tile {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "network-wireless-symbolic"
                            label: i18n("Wi-Fi")
                            status: root.backend && root.backend.wifiEnabled
                                ? (root.backend.wifiSsid !== "" ? root.backend.wifiSsid : i18n("On"))
                                : i18n("Off")
                            on: root.backend ? root.backend.wifiEnabled : false
                            hasDetails: true
                            onClicked: {
                                if (root.backend) {
                                    root.backend.setWifiEnabled(!root.backend.wifiEnabled)
                                }
                            }
                            onDetailsClicked: root.currentTab = "ag"
                        }

                        Tile {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "bluetooth-disabled-symbolic"
                            label: i18n("Bluetooth")
                            status: root.backend && root.backend.bluetoothEnabled ? i18n("On") : i18n("Off")
                            on: root.backend ? root.backend.bluetoothEnabled : false
                            hasDetails: true
                            onClicked: {
                                if (root.backend) {
                                    root.backend.setBluetoothEnabled(!root.backend.bluetoothEnabled)
                                }
                            }
                            onDetailsClicked: root.currentTab = "bluetooth"
                        }

                        Tile {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "notifications-disabled-symbolic"
                            label: i18n("Do Not Disturb")
                            status: root.backend && root.backend.dndEnabled ? i18n("On") : i18n("Off")
                            on: root.backend ? root.backend.dndEnabled : false
                            onClicked: {
                                if (root.backend) {
                                    root.backend.setDndEnabled(!root.backend.dndEnabled)
                                }
                            }
                        }

                        Tile {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "night-light-symbolic"
                            label: i18n("Night Light")
                            status: root.backend && root.backend.nightLightActive ? i18n("On") : i18n("Off")
                            on: root.backend ? root.backend.nightLightActive : false
                            onClicked: {
                                if (root.backend) {
                                    root.backend.toggleNightLight()
                                }
                            }
                        }

                        Tile {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "weather-clear-night-symbolic"
                            label: i18n("Dark Theme")
                            status: root.backend && root.backend.darkMode ? i18n("Dark") : i18n("Light")
                            on: root.backend ? root.backend.darkMode : false
                            onClicked: {
                                if (root.backend) {
                                    root.backend.setDarkMode(!root.backend.darkMode)
                                }
                            }
                        }

                        Tile {
                            visible: root.backend ? root.backend.keyboardLayouts.length > 1 : false
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "input-keyboard-symbolic"
                            label: i18n("Keyboard Layout")
                            status: root.backend && root.backend.keyboardLayouts.length > root.backend.currentLayout
                                ? root.backend.keyboardLayouts[root.backend.currentLayout].longName
                                : ""
                            hasDetails: true
                            onClicked: {
                                if (root.backend) {
                                    root.backend.nextLayout()
                                }
                            }
                            onDetailsClicked: root.currentTab = "klavye"
                        }

                        Tile {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            iconName: "airplane-mode-symbolic"
                            label: i18n("Airplane Mode")
                            status: root.backend && root.backend.airplaneMode ? i18n("On") : i18n("Off")
                            on: root.backend ? root.backend.airplaneMode : false
                            onClicked: {
                                if (root.backend) {
                                    root.backend.setAirplaneMode(!root.backend.airplaneMode)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.backend ? root.backend.powerProfilesAvailable : false
                        Layout.fillWidth: true
                        spacing: 4

                        PC3.Label {
                            text: i18n("Power profile")
                            font.pointSize: st.fontSmall
                            color: st.textMuted
                        }

                        PowerSelector {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            backend: root.backend
                        }
                    }

                    Rectangle {
                        visible: root.backend ? root.backend.hasBattery : false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: st.radiusCard
                        color: batteryMouse.containsMouse ? st.hover : st.glass
                        border.width: st.borderWidth
                        border.color: st.glassBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Kirigami.Icon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: root.backend && root.backend.charging ? "battery-good-charging-symbolic" : "battery-good-symbolic"
                                isMask: true
                                color: Kirigami.Theme.textColor
                            }

                            PC3.Label {
                                Layout.fillWidth: true
                                text: root.batterySummary()
                                color: Kirigami.Theme.textColor
                            }

                            Kirigami.Icon {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                source: "go-next-symbolic"
                                isMask: true
                                color: st.textMuted
                            }
                        }

                        MouseArea {
                            id: batteryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.currentTab = "guc"
                        }
                    }

                    SliderRow {
                        Layout.fillWidth: true
                        iconName: root.backend && root.backend.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                        value: root.backend ? root.backend.volume : 0
                        clickableIcon: true
                        onMoved: v => {
                            if (root.backend) {
                                root.backend.setVolume(v)
                            }
                        }
                        onIconClicked: {
                            if (root.backend) {
                                root.backend.setMuted(!root.backend.muted)
                            }
                        }
                    }

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
                }

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

                // Pano yalnız sekmesi açılınca yüklenir: KDE'nin pano arka ucu (Klipper) gereksiz başlamasın.
                Loader {
                    active: root.currentTab === "pano"
                    sourceComponent: ClipboardPage {
                        backend: root.backend
                    }
                }

                KeyboardPage {
                    backend: root.backend
                }
            }
        }
    }
}
