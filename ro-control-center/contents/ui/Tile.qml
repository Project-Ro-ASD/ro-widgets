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
    id: tile

    property string iconName: ""
    property string label: ""
    property string status: ""
    property bool on: false
    property bool hasDetails: false

    signal clicked()
    signal detailsClicked()

    Style {
        id: st
    }

    readonly property color fg: on ? st.onAccent : Kirigami.Theme.textColor

    implicitWidth: 160
    implicitHeight: 52
    radius: st.radiusCard
    color: on ? st.accent : st.glassRaised
    border.width: on ? 0 : st.borderWidth
    border.color: st.glassBorder

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: tile.clicked()

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: st.hover
        visible: mainMouse.containsMouse || detailsMouse.containsMouse
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: tile.hasDetails ? 0 : 10
        spacing: 8

        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: tile.iconName
            isMask: true
            color: tile.fg
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                Layout.fillWidth: true
                text: tile.label
                color: tile.fg
                elide: Text.ElideRight
            }

            PC3.Label {
                Layout.fillWidth: true
                text: tile.status
                elide: Text.ElideRight
                font.pointSize: st.fontSmall
                color: tile.on ? st.onAccent : st.textMuted
                opacity: tile.on ? 0.8 : 1.0
            }
        }

        Rectangle {
            visible: tile.hasDetails
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            color: tile.on ? st.onAccent : st.glassBorder
            opacity: tile.on ? 0.3 : 1.0
        }

        Item {
            id: detailsArea
            visible: tile.hasDetails
            Layout.preferredWidth: 28
            Layout.fillHeight: true

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: "go-next-symbolic"
                isMask: true
                color: tile.fg
            }
        }
    }

    MouseArea {
        id: mainMouse
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: tile.hasDetails ? detailsMouse.left : parent.right
        hoverEnabled: true
        onClicked: tile.clicked()
    }

    MouseArea {
        id: detailsMouse
        visible: tile.hasDetails
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: tile.hasDetails ? 28 : 0
        hoverEnabled: true
        onClicked: tile.detailsClicked()
    }
}
