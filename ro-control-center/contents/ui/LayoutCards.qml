/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons

Item {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend

    implicitWidth: 380
    implicitHeight: stackView.currentItem ? stackView.currentItem.implicitHeight : 360

    Style {
        id: st
    }

    function powerProfileLabel(profile) {
        if (profile === "power-saver") {
            return i18n("Power Save")
        }
        if (profile === "performance") {
            return i18n("Performance")
        }
        return i18n("Balanced")
    }

    function cyclePowerProfile() {
        if (!root.backend || !root.backend.powerProfiles || root.backend.powerProfiles.length === 0) {
            return
        }
        const list = root.backend.powerProfiles
        const idx = list.indexOf(root.backend.activeProfile)
        const next = list[(idx + 1) % list.length]
        root.backend.setPowerProfile(next)
    }

    // Genel görünümdeki pil özeti: "%64 · 0:52".
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

    function openSubPage(titleText, pageComp) {
        stackView.push(subPageWrapper, {
            pageTitle: titleText,
            pageComponent: pageComp
        })
    }

    Component {
        id: networkPageComp
        NetworkPage {
            backend: root.backend
        }
    }

    Component {
        id: bluetoothPageComp
        BluetoothPage {
            backend: root.backend
        }
    }

    Component {
        id: audioPageComp
        AudioPage {
            backend: root.backend
        }
    }

    Component {
        id: powerPageComp
        PowerPage {
            backend: root.backend
        }
    }

    Component {
        id: subPageWrapper

        ColumnLayout {
            property string pageTitle: ""
            property Component pageComponent

            spacing: RoTokens.spaceMd

            RowLayout {
                Layout.fillWidth: true
                spacing: RoTokens.spaceSm

                PC3.ToolButton {
                    icon.name: "go-previous-symbolic"
                    onClicked: stackView.pop()
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: parent.parent.pageTitle
                    color: Kirigami.Theme.textColor
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: parent.pageComponent
            }
        }
    }

    QQC2.StackView {
        id: stackView
        anchors.fill: parent

        initialItem: ColumnLayout {
            spacing: RoTokens.spaceMd

            ColumnLayout {
                Layout.fillWidth: true
                spacing: RoTokens.spaceSm

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
                    spacing: 8

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

                    PC3.ToolButton {
                        icon.name: "go-next-symbolic"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: root.openSubPage(i18n("Audio"), audioPageComp)
                    }
                }

                RowLayout {
                    visible: root.backend ? root.backend.brightnessAvailable : false
                    Layout.fillWidth: true
                    spacing: 8

                    SliderRow {
                        Layout.fillWidth: true
                        iconName: "display-brightness-symbolic"
                        value: root.backend ? root.backend.brightness : 0
                        onMoved: v => {
                            if (root.backend) {
                                root.backend.setBrightness(v)
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }
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
                    onClicked: root.openSubPage(i18n("Power"), powerPageComp)
                }
            }

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
                    onDetailsClicked: root.openSubPage(i18n("Wi-Fi"), networkPageComp)
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
                    onDetailsClicked: root.openSubPage(i18n("Bluetooth"), bluetoothPageComp)
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
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    iconName: "power-profile-balanced-symbolic"
                    label: i18n("Power Profile")
                    status: root.powerProfileLabel(root.backend ? root.backend.activeProfile : "balanced")
                    on: root.backend ? (root.backend.activeProfile !== "balanced" && root.backend.activeProfile !== "") : false
                    onClicked: root.cyclePowerProfile()
                }
            }
        }
    }
}
