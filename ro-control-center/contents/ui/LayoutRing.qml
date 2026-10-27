/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Item {
    // Renk seti popup'tan açıkça kalıtılsın; yazılmayınca Style örnekleri Kirigami.Theme'i siyah okuyor (ro-launcher ile aynı sorun).
    Kirigami.Theme.inherit: true
    id: root

    property var backend
    property string activeRing: "volume"

    implicitWidth: 380
    implicitHeight: stackView.currentItem ? stackView.currentItem.implicitHeight : 340

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

    function openSubPage(titleText, pageComp) {
        stackView.push(subPageWrapper, {
            pageTitle: titleText,
            pageComponent: pageComp
        })
    }

    component ToggleRow: Rectangle {
        id: rowRoot
        property string iconName: ""
        property string title: ""
        property string statusText: ""
        property bool active: false
        property bool hasDetails: false

        signal clicked()
        signal detailsClicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: st.radiusItem
        color: active ? st.accentSoft : (rowMouse.containsMouse || arrowMouse.containsMouse ? st.hover : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Kirigami.Icon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: rowRoot.iconName
                isMask: true
                color: rowRoot.active ? st.accent : Kirigami.Theme.textColor
            }

            PC3.Label {
                text: rowRoot.title
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
            }

            PC3.Label {
                text: rowRoot.statusText
                color: st.textMuted
                font.pointSize: st.fontSmall
            }

            Item {
                visible: rowRoot.hasDetails
                Layout.preferredWidth: 18
                Layout.fillHeight: true

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "go-next-symbolic"
                    isMask: true
                    color: st.textMuted
                }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: rowRoot.hasDetails ? arrowMouse.left : parent.right
            hoverEnabled: true
            onClicked: rowRoot.clicked()
        }

        MouseArea {
            id: arrowMouse
            visible: rowRoot.hasDetails
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: rowRoot.hasDetails ? 24 : 0
            hoverEnabled: true
            onClicked: rowRoot.detailsClicked()
        }
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

            RowLayout {
                Layout.fillWidth: true
                spacing: RoTokens.spaceSm

                PC3.Label {
                    text: i18n("Quick Settings")
                    Layout.fillWidth: true
                    color: Kirigami.Theme.textColor
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: RoTokens.spaceMd

                Item {
                    id: ringItem
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real volVal: root.backend ? root.backend.volume : 0
                    readonly property real brtVal: root.backend ? root.backend.brightness : 0

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: st.glassRaised
                            strokeWidth: 10
                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: 75
                                centerY: 75
                                radiusX: 66
                                radiusY: 66
                                startAngle: 135
                                sweepAngle: 270
                            }
                        }

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: st.accent
                            strokeWidth: 10
                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: 75
                                centerY: 75
                                radiusX: 66
                                radiusY: 66
                                startAngle: 135
                                sweepAngle: 270 * ringItem.volVal
                            }
                        }

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: st.glassRaised
                            strokeWidth: 10
                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: 75
                                centerY: 75
                                radiusX: 50
                                radiusY: 50
                                startAngle: 135
                                sweepAngle: 270
                            }
                        }

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: st.accent
                            strokeWidth: 10
                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: 75
                                centerY: 75
                                radiusX: 50
                                radiusY: 50
                                startAngle: 135
                                sweepAngle: 270 * ringItem.brtVal
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        PC3.Label {
                            text: Math.round((root.activeRing === "brightness" ? ringItem.brtVal : ringItem.volVal) * 100) + "%"
                            Layout.alignment: Qt.AlignHCenter
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.6
                            color: Kirigami.Theme.textColor
                        }

                        PC3.Label {
                            text: root.activeRing === "brightness" ? i18n("Brightness") : i18n("Volume")
                            Layout.alignment: Qt.AlignHCenter
                            color: st.textMuted
                            font.pointSize: st.fontSmall
                        }
                    }

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        spacing: 8

                        Kirigami.Icon {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            source: "audio-volume-high-symbolic"
                            isMask: true
                            color: st.textMuted
                        }

                        Kirigami.Icon {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            source: "display-brightness-symbolic"
                            isMask: true
                            color: st.textMuted
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        function updateFromPoint(mx, my, chooseRing) {
                            const dx = mx - 75
                            const dy = my - 75
                            const r = Math.sqrt(dx * dx + dy * dy)
                            if (chooseRing) {
                                root.activeRing = (r < 58 && root.backend && root.backend.brightnessAvailable) ? "brightness" : "volume"
                            }
                            let deg = Math.atan2(dy, dx) * 180 / Math.PI
                            if (deg < 0) {
                                deg += 360
                            }
                            let rel = deg - 135
                            if (rel < 0) {
                                rel += 360
                            }
                            if (rel > 270) {
                                rel = rel > 315 ? 0 : 270
                            }
                            const val = Math.max(0, Math.min(1, rel / 270))
                            if (!root.backend) {
                                return
                            }
                            if (root.activeRing === "brightness" && root.backend.brightnessAvailable) {
                                root.backend.setBrightness(val)
                            } else {
                                root.backend.setVolume(val)
                            }
                        }

                        onPressed: mouse => updateFromPoint(mouse.x, mouse.y, true)
                        onPositionChanged: mouse => {
                            if (pressed) {
                                updateFromPoint(mouse.x, mouse.y, false)
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    ToggleRow {
                        iconName: "network-wireless-symbolic"
                        title: i18n("Wi-Fi")
                        statusText: root.backend && root.backend.wifiEnabled
                            ? (root.backend.wifiSsid !== "" ? root.backend.wifiSsid : i18n("On"))
                            : i18n("Off")
                        active: root.backend ? root.backend.wifiEnabled : false
                        hasDetails: true
                        onClicked: {
                            if (root.backend) {
                                root.backend.setWifiEnabled(!root.backend.wifiEnabled)
                            }
                        }
                        onDetailsClicked: root.openSubPage(i18n("Wi-Fi"), networkPageComp)
                    }

                    ToggleRow {
                        iconName: "bluetooth-disabled-symbolic"
                        title: i18n("Bluetooth")
                        statusText: root.backend && root.backend.bluetoothEnabled ? i18n("On") : i18n("Off")
                        active: root.backend ? root.backend.bluetoothEnabled : false
                        hasDetails: true
                        onClicked: {
                            if (root.backend) {
                                root.backend.setBluetoothEnabled(!root.backend.bluetoothEnabled)
                            }
                        }
                        onDetailsClicked: root.openSubPage(i18n("Bluetooth"), bluetoothPageComp)
                    }

                    ToggleRow {
                        iconName: "notifications-disabled-symbolic"
                        title: i18n("Do Not Disturb")
                        statusText: root.backend && root.backend.dndEnabled ? i18n("On") : i18n("Off")
                        active: root.backend ? root.backend.dndEnabled : false
                        onClicked: {
                            if (root.backend) {
                                root.backend.setDndEnabled(!root.backend.dndEnabled)
                            }
                        }
                    }

                    ToggleRow {
                        iconName: "night-light-symbolic"
                        title: i18n("Night Light")
                        statusText: root.backend && root.backend.nightLightActive ? i18n("On") : i18n("Off")
                        active: root.backend ? root.backend.nightLightActive : false
                        onClicked: {
                            if (root.backend) {
                                root.backend.toggleNightLight()
                            }
                        }
                    }

                    ToggleRow {
                        iconName: "weather-clear-night-symbolic"
                        title: i18n("Dark Theme")
                        statusText: root.backend && root.backend.darkMode ? i18n("Dark") : i18n("Light")
                        active: root.backend ? root.backend.darkMode : false
                        onClicked: {
                            if (root.backend) {
                                root.backend.setDarkMode(!root.backend.darkMode)
                            }
                        }
                    }

                    ToggleRow {
                        iconName: "power-profile-balanced-symbolic"
                        title: i18n("Power Profile")
                        statusText: root.powerProfileLabel(root.backend ? root.backend.activeProfile : "balanced")
                        active: root.backend ? (root.backend.activeProfile !== "balanced" && root.backend.activeProfile !== "") : false
                        onClicked: root.cyclePowerProfile()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: st.radiusCard
                color: speakerMouse.containsMouse ? st.hover : st.glass
                border.width: st.borderWidth
                border.color: st.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Kirigami.Icon {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        source: "audio-volume-high-symbolic"
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }

                    PC3.Label {
                        text: root.backend && root.backend.defaultSink
                            ? (root.backend.defaultSink.description || root.backend.defaultSink.name || i18n("Speaker"))
                            : i18n("Speaker")
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Kirigami.Theme.textColor
                    }

                    Kirigami.Icon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: "go-next-symbolic"
                        isMask: true
                        color: st.textMuted
                    }
                }

                MouseArea {
                    id: speakerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSubPage(i18n("Audio"), audioPageComp)
                }
            }
        }
    }
}
