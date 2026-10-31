/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Templates as T
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.clipboard as Private

Item {
    id: root
    // Renk seti popup'tan açıkça kalıtılsın
    Kirigami.Theme.inherit: true

    property var backend

    implicitWidth: parent ? parent.width : 320
    implicitHeight: Math.max(mainLayout.implicitHeight, 320)
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 320

    readonly property bool isClipboardEmpty: historyModel.sourceCount === 0

    Style {
        id: st
    }

    Private.KlipperInterface {
        id: klipper
    }

    Private.HistoryModel {
        id: historyModel
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Üst başlık satırı ve pano eylemleri
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PC3.Label {
                Layout.fillWidth: true
                text: i18nd("plasma_applet_org.kde.plasma.clipboard", "Clipboard")
                color: Kirigami.Theme.textColor
                elide: Text.ElideRight
            }

            PC3.ToolButton {
                id: clearButton
                visible: !root.isClipboardEmpty && !clipboardMenu.editing
                icon.name: "edit-clear-history"
                display: PC3.AbstractButton.IconOnly
                text: i18nd("plasma_applet_org.kde.plasma.clipboard", "Clear History")
                onClicked: clipboardMenu.clearHistory()

                PC3.ToolTip {
                    text: clearButton.text
                }
            }

            PC3.ToolButton {
                id: configureButton
                icon.name: "configure"
                display: PC3.AbstractButton.IconOnly
                text: i18nd("plasma_applet_org.kde.plasma.clipboard", "Configure Clipboard…")
                onClicked: klipper.configure()

                PC3.ToolTip {
                    text: configureButton.text
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: st.glassBorder
        }

        // ClipboardMenu zorunlu dialogItem (PlasmaExtras.Representation) ve T.StackView bağlamı gerektirir; KDE main.qml'deki gibi bağlanır
        PlasmaExtras.Representation {
            id: dialogItem
            Layout.fillWidth: true
            Layout.fillHeight: true
            collapseMarginsHint: true
            focus: true

            header: stack.currentItem.header

            readonly property alias clipboardMenu: stack.initialItem

            Keys.forwardTo: [stack.currentItem]

            QQC2.StackView {
                id: stack
                anchors.fill: parent
                initialItem: Private.ClipboardMenu {
                    id: clipboardMenu
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    expanded: root.visible
                    dialogItem: dialogItem
                    model: historyModel
                    // Temizle düğmesi bizim başlıkta; KDE menüsündekini gösterme.
                    showsClearHistoryButton: false
                    // KDE pano widget'ının varsayılanı (main.xml); bizde ayarı yok.
                    barcodeType: "QRCode"
                    showHeader: Plasmoid.containment.pluginName !== "org.kde.plasma.systemtray"
                }
            }
        }
    }
}
