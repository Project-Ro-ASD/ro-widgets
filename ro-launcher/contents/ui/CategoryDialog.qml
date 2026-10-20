/*
    SPDX-FileCopyrightText: 2026 Project Ro-ASD

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Kategori adı girişi (yeni / yeniden adlandır) ve silme onayı. Popup'ın ortasında açılan kart;
// kararma katmanı FullRepresentation'da (güç menüsüyle aynı).
Item {
    id: root

    property var store: null

    // "new" | "rename" | "delete"
    property string mode: ""
    property int categoryIndex: -1
    property string appId: ""
    property string categoryName: ""

    readonly property bool open: mode !== ""

    readonly property Style st: styleItem
    Style {
        id: styleItem
    }

    function openName(newMode, index, app, initialName) {
        mode = newMode;
        categoryIndex = index;
        appId = app;
        nameField.text = initialName;
        nameField.selectAll();
        nameField.forceActiveFocus();
    }

    function openDelete(index, name) {
        mode = "delete";
        categoryIndex = index;
        categoryName = name;
        cancelButton.forceActiveFocus();
    }

    function close() {
        mode = "";
    }

    function accept() {
        if (mode === "delete") {
            store?.removeCategory(categoryIndex);
        } else if (nameField.text.trim().length > 0) {
            store?.applyName(mode, categoryIndex, appId, nameField.text);
        } else {
            return;
        }
        close();
    }

    // Launcher kapanınca açık pencere de kapanır
    Connections {
        target: kickoff
        function onExpandedChanged() {
            if (!kickoff.expanded) {
                root.close();
            }
        }
    }

    Connections {
        target: root.store
        function onNameRequested(mode, index, appId, initialName) {
            root.openName(mode, index, appId, initialName);
        }
        function onDeleteRequested(index, name) {
            root.openDelete(index, name);
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(380, root.width - 48)
        height: content.implicitHeight + 32
        radius: root.st.radiusCard
        color: root.st.surfaceSolid
        border.color: root.st.borderStrong
        border.width: root.st.borderWidth

        visible: opacity > 0
        opacity: root.open ? 1.0 : 0.0
        scale: root.open ? 1.0 : 0.96
        Behavior on opacity { NumberAnimation { duration: root.st.durationShort } }
        Behavior on scale { NumberAnimation { duration: root.st.durationLong; easing.type: Easing.OutCubic } }

        // Kartın boş yerine tıklama kararma katmanına geçip pencereyi kapatmasın
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.mode === "rename" ? i18n("Rename Category")
                    : root.mode === "delete" ? i18n("Delete Category")
                    : i18n("New Category")
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            PlasmaComponents.TextField {
                id: nameField
                Layout.fillWidth: true
                visible: root.mode !== "delete"
                placeholderText: i18n("Category name")
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
                Keys.onEscapePressed: root.close()
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: root.mode === "delete"
                text: i18n("Delete “%1”? The applications themselves are not removed.", root.categoryName)
                wrapMode: Text.Wrap
                color: root.st.textMuted
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                PlasmaComponents.Button {
                    id: cancelButton
                    text: i18n("Cancel")
                    icon.name: "dialog-cancel"
                    onClicked: root.close()
                    Keys.onEscapePressed: root.close()
                }

                PlasmaComponents.Button {
                    text: root.mode === "delete" ? i18n("Delete Category") : i18n("OK")
                    icon.name: root.mode === "delete" ? "edit-delete" : "dialog-ok"
                    enabled: root.mode === "delete" || nameField.text.trim().length > 0
                    onClicked: root.accept()
                }
            }
        }
    }
}
