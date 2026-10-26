/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Backend {
        id: backend
    }

    Plasmoid.icon: "preferences-system"

    compactRepresentation: Item {
        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: mouseArea.containsMouse
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        // Düzen kendi boyutunu verir; popup ondan küçülmesin.
        Layout.minimumWidth: loader.item ? loader.item.implicitWidth : 420
        Layout.minimumHeight: loader.item ? loader.item.implicitHeight : 480
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        Loader {
            id: loader
            anchors.fill: parent
            source: ({
                ro: "LayoutRo.qml",
                kartlar: "LayoutCards.qml",
                halka: "LayoutRing.qml",
                sekmeler: "LayoutSideTabs.qml"
            })[Plasmoid.configuration.layout] ?? "LayoutRo.qml"
            onLoaded: {
                if (item) {
                    item.backend = backend
                }
            }
        }
    }
}
