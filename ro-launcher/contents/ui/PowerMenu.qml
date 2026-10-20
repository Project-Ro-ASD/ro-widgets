/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.sessions as Sessions
import org.kde.kirigami as Kirigami

// Sağ alttaki güç düğmesi + açılan oturum/güç kartı.
// Kararma katmanı FullRepresentation'da; bu bileşen sadece düğmeyi ve kartı çizer.
Item {
    id: root

    // FullRepresentation'ın doğrudan çocuğunda renk seti açıkça kalıtılmazsa Style zemini siyah okuyor
    Kirigami.Theme.inherit: true

    // Durum NormalPage.powerOverlayVisible'da; bu bileşen sadece istek sinyali yollar
    property bool open: false
    signal toggleRequested()
    signal closeRequested()

    // Tema renkleri bu bileşenin bulunduğu yerden (popup) kalıtılsın diye yerel örnek
    readonly property Style st: styleItem
    Style {
        id: styleItem
    }

    Sessions.SessionManagement {
        id: session
    }

    function run(callback) {
        root.closeRequested();
        kickoff.expanded = false;
        callback();
    }

    Rectangle {
        id: powerTrigger
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 12
        anchors.bottomMargin: 8
        width: 38
        height: 38
        radius: height / 2
        // Sadece bu düğme "tehlike" rengini kullanır
        color: pwrMouse.containsMouse || root.open ? root.st.danger : root.st.glassRaised
        border.color: root.st.border
        border.width: root.st.borderWidth

        Behavior on color { ColorAnimation { duration: root.st.durationShort } }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: "system-shutdown"
            color: pwrMouse.containsMouse || root.open ? root.st.onDanger : Kirigami.Theme.textColor
        }

        MouseArea {
            id: pwrMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested()
        }
    }

    Rectangle {
        id: powerCard
        anchors.right: powerTrigger.left
        anchors.rightMargin: 12
        anchors.bottom: powerTrigger.bottom
        width: 410
        height: 108
        radius: root.st.radiusCard
        color: root.st.surfaceSolid
        border.color: root.st.borderStrong
        border.width: root.st.borderWidth

        visible: opacity > 0
        opacity: root.open ? 1.0 : 0.0
        scale: root.open ? 1.0 : 0.94
        transformOrigin: Item.BottomRight

        Behavior on opacity { NumberAnimation { duration: root.st.durationShort } }
        Behavior on scale { NumberAnimation { duration: root.st.durationLong; easing.type: Easing.OutCubic } }

        // Kartın boş yerine tıklama kararma katmanına geçip menüyü kapatmasın
        MouseArea { anchors.fill: parent }

        GridLayout {
            anchors.fill: parent
            anchors.margins: 8
            columns: 3
            rows: 2
            rowSpacing: 6
            columnSpacing: 6

            component PowerCapsule: Rectangle {
                id: cap
                property string label: ""
                property string iconSource: ""
                signal triggered()

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: height / 2
                opacity: enabled ? 1.0 : 0.4
                // Hover nötr ton; vurgu rengi yalnızca basılıyken
                color: capMouse.pressed ? root.st.accentSoft : (capMouse.containsMouse ? root.st.hover : root.st.glassRaised)
                border.color: capMouse.pressed ? root.st.accentBorder : "transparent"
                border.width: root.st.borderWidth

                Behavior on color { ColorAnimation { duration: root.st.durationShort } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        source: cap.iconSource
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                    }

                    PlasmaComponents.Label {
                        text: cap.label
                        font.pointSize: root.st.fontNormal
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: capMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cap.triggered()
                }
            }

            PowerCapsule {
                label: i18nd("libkicker", "Lock")
                iconSource: "system-lock-screen"
                enabled: session.canLock
                onTriggered: root.run(() => session.lock())
            }
            PowerCapsule {
                label: i18nd("libkicker", "Log Out")
                iconSource: "system-log-out"
                enabled: session.canLogout
                onTriggered: root.run(() => session.requestLogout())
            }
            PowerCapsule {
                label: i18nd("libkicker", "Switch User")
                iconSource: "system-switch-user"
                enabled: session.canSwitchUser
                onTriggered: root.run(() => session.switchUser())
            }
            PowerCapsule {
                label: i18ndc("libkicker", "Suspend to RAM", "Sleep")
                iconSource: "system-suspend"
                enabled: session.canSuspend
                onTriggered: root.run(() => session.suspend())
            }
            PowerCapsule {
                label: i18nd("libkicker", "Restart")
                iconSource: "system-reboot"
                enabled: session.canReboot
                onTriggered: root.run(() => session.requestReboot())
            }
            PowerCapsule {
                label: i18nd("libkicker", "Shut Down")
                iconSource: "system-shutdown"
                enabled: session.canShutdown
                onTriggered: root.run(() => session.requestShutdown())
            }
        }
    }
}
