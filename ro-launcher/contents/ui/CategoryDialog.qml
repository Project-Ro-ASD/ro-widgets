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
    onOpenChanged: if (store) store.dialogOpen = open

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
        focusTimer.restart();
    }

    function openDelete(index, name) {
        mode = "delete";
        categoryIndex = index;
        categoryName = name;
        focusTimer.restart();
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

    function takeFocus() {
        if (mode === "delete") {
            acceptButton.forceActiveFocus();
        } else if (open) {
            nameField.forceActiveFocus();
        }
    }

    // Pencere sağ tık menüsünden açılınca menü kapanırken odağı eski yerine (ana sayfa → arama
    // çubuğu) geri veriyor. Odak menü kapandıktan sonra ve kapanınca yeniden alınır.
    Timer {
        id: focusTimer
        interval: 1
        onTriggered: root.takeFocus()
    }

    Connections {
        target: ActionMenu.menu
        function onStatusChanged() {
            if (root.open) {
                focusTimer.restart();
            }
        }
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
        function onDialogCloseRequested() {
            root.close();
        }
        // Odak yine de ana sayfada kaldıysa yazılan harf kaybolmasın
        function onDialogKeyTyped(text) {
            if (root.mode !== "delete") {
                nameField.forceActiveFocus();
                nameField.insert(nameField.cursorPosition, text);
            }
        }
    }

    // Launcher'ın kendi düğme dili (güç menüsü kapsülleriyle aynı): nötr hover, odakta vurgu halkası
    component DialogButton: Rectangle {
        id: btn
        property string text: ""
        property string iconName: ""
        property bool primary: false
        property bool destructive: false
        signal clicked()
        // Hover'da dolu vurgu / tehlike rengine geçen düğmede yazı o rengin üstündeki renk olur
        readonly property bool onFill: btnMouse.containsMouse && !btnMouse.pressed && (destructive || primary)

        implicitWidth: btnRow.implicitWidth + 28
        implicitHeight: 34
        radius: root.st.radiusItem
        opacity: enabled ? 1.0 : 0.45
        activeFocusOnTab: true
        // Hover: belirgin renk geçişi ve çok küçük büyüme; basınca hafif küçülür
        color: btnMouse.pressed ? root.st.pressed
            : btnMouse.containsMouse ? (destructive ? root.st.danger : primary ? root.st.accentBorder : root.st.pressed)
            : primary ? root.st.accentSoft : root.st.glassRaised
        scale: btnMouse.pressed ? 0.98 : (btnMouse.containsMouse ? 1.03 : 1.0)
        Behavior on scale { NumberAnimation { duration: root.st.durationShort; easing.type: Easing.OutCubic } }
        border.color: activeFocus ? Kirigami.Theme.focusColor : (primary ? root.st.accentBorder : root.st.border)
        border.width: activeFocus ? 2 : root.st.borderWidth

        Accessible.role: Accessible.Button
        Accessible.name: text
        Accessible.onPressAction: btn.clicked()

        Behavior on color { ColorAnimation { duration: root.st.durationShort } }

        Keys.onReturnPressed: btn.clicked()
        Keys.onEnterPressed: btn.clicked()
        Keys.onSpacePressed: btn.clicked()
        Keys.onEscapePressed: root.close()

        RowLayout {
            id: btnRow
            anchors.centerIn: parent
            spacing: 6

            Kirigami.Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: btn.iconName
                isMask: true
                color: btn.onFill ? (btn.destructive ? root.st.onDanger : root.st.onAccent) : Kirigami.Theme.textColor
            }

            PlasmaComponents.Label {
                text: btn.text
                color: btn.onFill ? (btn.destructive ? root.st.onDanger : root.st.onAccent) : Kirigami.Theme.textColor
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
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

                DialogButton {
                    text: i18n("Cancel")
                    iconName: "dialog-cancel"
                    onClicked: root.close()
                }

                DialogButton {
                    id: acceptButton
                    text: root.mode === "delete" ? i18n("Delete Category") : i18n("OK")
                    iconName: root.mode === "delete" ? "edit-delete" : "dialog-ok"
                    primary: root.mode !== "delete"
                    destructive: root.mode === "delete"
                    enabled: root.mode === "delete" || nameField.text.trim().length > 0
                    onClicked: root.accept()
                }
            }
        }
    }
}
