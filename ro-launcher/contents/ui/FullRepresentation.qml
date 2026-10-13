/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import Qt5Compat.GraphicalEffects

// Popup'ın dış kenarı ve köşeleri Plasma temasının "dialogs/background" SVG'sinden gelir;
// yuvarlaklık launcher'da değil temada ayarlanır.
EmptyPage {
    id: root

    readonly property bool useClassic: Plasmoid.configuration.useClassicCategoriesView ?? false
    // Tema renkleri bu bileşenin bulunduğu yerden (popup) kalıtılsın diye yerel örnek
    readonly property Style st: styleItem
    Style {
        id: styleItem
    }

    // Klasik modda çift sütun sığsın diye genişliği 700px yapıyoruz
    Layout.minimumWidth: useClassic ? 660 : 540
    Layout.preferredWidth: useClassic ? 720 : 640
    Layout.maximumWidth: 860

    Layout.minimumHeight: 480
    Layout.preferredHeight: 560
    Layout.maximumHeight: 720

    property alias normalPage: normalPageItem

    Connections {
        target: kickoff
        function onExpandedChanged() {
            if (!kickoff.expanded) {
                if (normalPageItem) {
                    normalPageItem.resetToHome();
                }
            } else {
                // Odak arama alanına değil sayfaya: imleç yanıp sönmez, yazılan harfler yine aramaya gider
                normalPageItem.forceActiveFocus();
            }
        }
    }

    // Güç menüsü açılınca arkadaki her şey kararır (scrim aşağıda)
    Item {
        id: content
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Header {
                id: headerItem
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                overlayOpen: normalPageItem.powerOverlayVisible
                onBackgroundClicked: normalPageItem.resetToHome()
                onSearchRequested: normalPageItem.openSubPages()
                onSearchAccepted: normalPageItem.activateSearchResult()
                onSearchNavigate: delta => normalPageItem.moveSearchSelection(delta)
                onOverlayCloseRequested: normalPageItem.powerOverlayVisible = false
            }

            NormalPage {
                id: normalPageItem
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // Karartma: popup penceresinin tamamını (tema çerçevesi dahil) kaplar ve şeklini temanın
    // dialog SVG'sinden alır; tema köşeleri nasıl çizerse karartma da birebir o şekle oturur.
    Item {
        id: scrim

        // İçeriğin pencere içindeki konumu (dialog kenar boşlukları); boyut değişince yeniden hesaplanır
        readonly property point windowOffset: {
            root.width; root.height; root.Window.width; root.Window.height;
            return parent ? parent.mapToItem(null, 0, 0) : Qt.point(0, 0);
        }
        x: -windowOffset.x
        y: -windowOffset.y
        width: root.Window.width > 0 ? root.Window.width : root.width
        height: root.Window.height > 0 ? root.Window.height : root.height

        visible: opacity > 0
        opacity: normalPageItem.powerOverlayVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: root.st.durationShort } }

        KSvg.FrameSvgItem {
            id: scrimShape
            anchors.fill: parent
            imagePath: "dialogs/background"
            visible: false
        }

        Rectangle {
            id: scrimFill
            anchors.fill: parent
            color: root.st.scrim
            visible: false
        }

        // Şeffaf temalarda SVG'nin alfa değeri düşük olabilir; eşik maskesi şekli alır ama rengi soldurmaz
        ThresholdMask {
            anchors.fill: parent
            source: scrimFill
            maskSource: scrimShape
            threshold: 0.05
            spread: 0.1
        }

        MouseArea {
            anchors.fill: parent
            onClicked: normalPageItem.powerOverlayVisible = false
        }
    }

    PowerMenu {
        anchors.fill: parent
        open: normalPageItem.powerOverlayVisible
        onToggleRequested: normalPageItem.powerOverlayVisible = !normalPageItem.powerOverlayVisible
        onCloseRequested: normalPageItem.powerOverlayVisible = false
    }

    Component.onCompleted: {
        kickoff.header = headerItem;
        if (normalPageItem) {
            normalPageItem.resetToHome();
        }
        normalPageItem.forceActiveFocus();
    }
}
