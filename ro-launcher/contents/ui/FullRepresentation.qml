/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import Qt5Compat.GraphicalEffects

// Popup'ın dış kenarı ve köşeleri Plasma temasının "dialogs/background" SVG'sinden gelir;
// yuvarlaklık launcher'da değil temada ayarlanır.
EmptyPage {
    id: root

    // Renk seti popup'tan açıkça kalıtılsın. Yazılmayınca buradaki ve doğrudan çocuklardaki (başlık, güç menüsü,
    // kategori penceresi) Style örnekleri Kirigami.Theme'i siyah okuyordu: arama çubuğunda siyah kenar, simsiyah kartlar.
    Kirigami.Theme.inherit: true

    readonly property bool useClassic: Plasmoid.configuration.useClassicCategoriesView ?? false
    // Tema renkleri bu bileşenin bulunduğu yerden (popup) kalıtılsın diye yerel örnek
    readonly property Style st: styleItem
    Style {
        id: styleItem
    }

    // Klasik modda çift sütun sığsın diye genişliği 700px yapıyoruz
    // WGT-09: tasarım ölçüleri mantıksal piksel (ekran ölçeğiyle büyür) ama ekranın kullanılabilir alanını aşamaz.
    // Küçük ekranda büyük ölçekte (ör. 1280×800 %150 = 853×533) sabit 560 yükseklik popup'ı ekrandan taşırıyordu.
    // Panel ve popup kenarı için 4 gridUnit pay; Wayland'de desktopAvailable* panel alanını düşmeyebilir.
    readonly property real screenFitWidth: Screen.desktopAvailableWidth - Kirigami.Units.gridUnit * 2
    readonly property real screenFitHeight: Screen.desktopAvailableHeight - Kirigami.Units.gridUnit * 4
    Layout.minimumWidth: Math.min(useClassic ? 660 : 540, screenFitWidth)
    // Varsayılan genişlik ızgaralara tam oturur (hücre en az 90 px): ana ekranda 6 sütun × 102 px, sekme ekranında
    // 5 sütun × 91 px; ana ekranın kaydırma çubuğu kartların dışında. Kullanıcı popup'ı büyütüp küçültebilir.
    Layout.preferredWidth: Math.min(useClassic ? 720 : 660, screenFitWidth)
    Layout.maximumWidth: Math.min(860, screenFitWidth)

    Layout.minimumHeight: Math.min(480, screenFitHeight)
    Layout.preferredHeight: Math.min(560, screenFitHeight)
    Layout.maximumHeight: Math.min(720, screenFitHeight)

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
        opacity: normalPageItem.powerOverlayVisible || categoryDialog.open ? 1.0 : 0.0
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
            onClicked: {
                normalPageItem.powerOverlayVisible = false;
                categoryDialog.close();
            }
        }
    }

    PowerMenu {
        anchors.fill: parent
        open: normalPageItem.powerOverlayVisible
        onToggleRequested: normalPageItem.powerOverlayVisible = !normalPageItem.powerOverlayVisible
        onCloseRequested: normalPageItem.powerOverlayVisible = false
    }

    // Kategori adı / silme onayı (CategoryStore isteğiyle açılır)
    CategoryDialog {
        id: categoryDialog
        anchors.fill: parent
        store: kickoff.categoryStore
        z: 10
    }

    Component.onCompleted: {
        kickoff.header = headerItem;
        if (normalPageItem) {
            normalPageItem.resetToHome();
        }
        normalPageItem.forceActiveFocus();
    }
}
