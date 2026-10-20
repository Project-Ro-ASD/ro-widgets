/*
    SPDX-FileCopyrightText: 2026 Hasan OKSUZ

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "code/tools.js" as Tools

Item {
    id: root

    property bool useClassicView: Plasmoid.configuration.useClassicCategoriesView ?? false

    Connections {
        target: Plasmoid.configuration
        function onUseClassicCategoriesViewChanged() {
            root.useClassicView = Plasmoid.configuration.useClassicCategoriesView;
        }
    }

    // Tema renkleri bu bileşenin bulunduğu yerden (popup) kalıtılsın diye yerel örnek
    readonly property Style st: styleItem
    Style {
        id: styleItem
    }

    readonly property real defaultSideBarWidth: 190

    readonly property bool searchHasFocus: kickoff?.searchField?.activeFocus ?? false
    readonly property string searchText: kickoff?.searchField?.text ?? ""
    readonly property bool isSearching: searchText.trim().length > 0

    property bool manualClosed: false
    property bool subPagesActive: false
    property bool isMenuOpen: false

    readonly property bool isExpanded: root.useClassicView || (!manualClosed && (isSearching || subPagesActive))

    property int currentTab: 0
    property int classicBottomTab: 0 // 0: Applications, 1: Places

    // Güç menüsünün kendisi FullRepresentation'da (PowerMenu); durum burada tutuluyor
    property bool powerOverlayVisible: false

    // 0 = ana ekran (kompakt favori kartı), 1 = sekmeler/arama (tam kart). Kart yüksekliği ve
    // içeriğin kayarak/solarak gelmesi buna bağlı.
    property real expandProgress: (root.useClassicView || root.isExpanded) ? 1 : 0
    Behavior on expandProgress {
        NumberAnimation { duration: root.st.durationLong; easing.type: Easing.OutCubic }
    }

    // rootModel yenilenince (ör. sıralama/isim biçimi ayarı değişince) alt modeller yeniden
    // oluşturuluyor; modelForRow bağımlılık kurmadığı için "Tüm Uygulamalar" modelini yeniden bağla
    property int rootModelRevision: 0
    Connections {
        target: kickoff.rootModel
        function onRefreshed() {
            root.rootModelRevision++;
        }
    }

    Kirigami.Theme.inherit: true

    function performDrag(handler, delegateItem, iconItem, url) {
        if (!kickoff?.dragSource) return;

        if (!handler.active) {
            kickoff.dragSource.Drag.active = false;
            kickoff.dragSource.Drag.imageSource = "";
            kickoff.dragSource.sourceItem = null;
            return;
        }

        if (iconItem) {
            iconItem.grabToImage(result => {
                if (!handler.active) return;
                kickoff.dragSource.sourceItem = delegateItem;
                kickoff.dragSource.Drag.imageSource = result.url;
                kickoff.dragSource.Drag.mimeData = {
                    "text/uri-list": [url]
                };
                kickoff.dragSource.Drag.active = handler.active;
            });
        }
    }

    // Bir öğeyi başlatır; model kapanma isterse (uygulama açıldı vb.) launcher'ı kapatır
    function launch(model, index) {
        if (!model) return;
        const closeRequested = model.trigger(index, "", null);
        root.resetToHome();
        if (closeRequested && kickoff.hideOnWindowDeactivate) {
            kickoff.expanded = false;
        }
    }

    //BEGIN Arama klavye gezinmesi (Header'daki arama çubuğundan çağrılır)
    function moveSearchSelection(delta) {
        if (!root.isSearching || directSearchView.count === 0) return;
        const next = Math.max(0, Math.min(directSearchView.count - 1, directSearchView.currentIndex + delta));
        directSearchView.currentIndex = next;
        directSearchView.positionViewAtIndex(next, ListView.Contain);
    }

    function activateSearchResult() {
        if (!root.isSearching || directSearchView.count === 0) return;
        const index = directSearchView.currentIndex >= 0 ? directSearchView.currentIndex : 0;
        root.launch(directSearchView.model, index);
    }
    //END

    Connections {
        target: kickoff
        function onExpandedChanged() {
            if (!kickoff.expanded) {
                root.resetToHome();
            }
        }
    }

    function openSubPages() {
        if (root.useClassicView) return;
        root.manualClosed = false;
        root.subPagesActive = true;
    }

    focus: true
    Keys.forwardTo: kickoff?.searchField ? [kickoff.searchField] : []
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            // Güç menüsü açıksa sadece onu kapat; değilse olayı bırak, Plasma launcher'ı kapatsın
            if (root.powerOverlayVisible) {
                root.powerOverlayVisible = false;
                event.accepted = true;
            }
            return;
        }
        // Tuşlar Keys.forwardTo ile arama alanına odak verilmeden gidiyor: yazınca arama başlar
        // ama imleç yanıp sönmez. Alan tuşu kabul etmediyse metni biz ekleriz.
        const field = kickoff?.searchField;
        if (field && event.text.trim().length > 0) {
            field.insert(field.cursorPosition, event.text);
            event.accepted = true;
        }
    }

    Connections {
        target: kickoff?.searchField ?? null
        function onTextChanged() {
            directSearchView.currentIndex = 0;
            if (root.searchText.length > 0 && !root.useClassicView) {
                root.openSubPages();
            }
        }
    }

    Connections {
        target: kickoff?.header ?? null
        function onBackgroundClicked() {
            if (!root.useClassicView) {
                root.resetToHome();
            }
        }
    }

    function resetToHome() {
        root.powerOverlayVisible = false;
        root.subPagesActive = false;
        root.isMenuOpen = false;
        root.currentTab = 0;
        root.classicBottomTab = 0;
        if (classicStackView && classicAppsPage && classicStackView.currentItem !== classicAppsPage) {
            classicStackView.replace(classicAppsPage);
        }
        if (ActionMenu.menu) {
            ActionMenu.menu.close();
        }
        root.manualClosed = true;
        if (kickoff?.searchField) {
            kickoff.searchField.text = "";
            kickoff.searchField.focus = false;
        }
        root.forceActiveFocus();
    }

    function openNativeActionMenu(visualDelegate, modelDataRef, mouseX, mouseY, fromSubPages = false) {
        var rawActions = modelDataRef.actionList || modelDataRef.actions;
        var actions = rawActions ? Array.from(rawActions) : [];

        var favModel = kickoff?.rootModel?.favoritesModel ?? null;
        var favId = modelDataRef.favoriteId ?? modelDataRef.url ?? "";

        var favoriteActions = null;
        if (favModel && favId) {
            try {
                favoriteActions = Tools.createFavoriteActions(msg => i18nd("plasma_applet_org.kde.plasma.kickoff", msg), favModel, favId);
            } catch(e) {
                favoriteActions = null;
            }
        }

        if (favoriteActions && favoriteActions.length > 0) {
            var firstAddIdx = actions.findIndex(a => ["addToDesktop", "addToTaskManager", "addToPanel"].includes(a?.actionId));
            if (firstAddIdx >= 0) {
                actions.splice(firstAddIdx, 0, ...favoriteActions);
            } else {
                actions.push(...favoriteActions);
            }
        }

        if (actions.length === 0) return;

        if (fromSubPages && !root.useClassicView) {
            root.subPagesActive = true;
        }
        root.isMenuOpen = true;

        // ActionMenu bir singleton: klasik moddaki delegelerle aynı menü
        ActionMenu.plasmoid = kickoff;
        ActionMenu.menu.visualParent = visualDelegate;
        ActionMenu.actionList = actions;
        ActionMenu.menu.open(mouseX, mouseY);
    }

    Connections {
        target: ActionMenu.menu
        function onStatusChanged() {
            if (ActionMenu.menu.status === PlasmaExtras.Menu.Closed) {
                root.isMenuOpen = false;
            }
        }
    }

    component AppGridItemDelegate: Item {
        id: delegateRoot
        property var parentView: null
        property var modelRef: null

        width: 90
        height: 94

        readonly property var view: parentView
        readonly property int index: model.index
        readonly property string itemUrl: model.url ?? ""

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: root.st.radiusItem
            color: mouseArea.pressed ? root.st.pressed : (mouseArea.containsMouse ? root.st.hover : "transparent")

            Behavior on color { ColorAnimation { duration: root.st.durationShort } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Kirigami.Icon {
                    id: gridIconItem
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    source: model.decoration ?? model.icon ?? "application-x-executable"
                }

                PlasmaComponents.Label {
                    Layout.preferredWidth: 80
                    text: model.display ?? ""
                    font.pointSize: root.st.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            DragHandler {
                id: gDragHandler
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                target: null
                onActiveChanged: root.performDrag(this, delegateRoot, gridIconItem, delegateRoot.itemUrl)
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: gDragHandler.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                onClicked: mouse => {
                    if (gDragHandler.active) return;
                    if (mouse.button === Qt.RightButton) {
                        root.openNativeActionMenu(delegateRoot, model, mouse.x, mouse.y, true);
                    } else {
                        root.launch(delegateRoot.modelRef, delegateRoot.index);
                    }
                }
            }
        }
    }

    // Boş alana tıklayınca aramadan çıkış dinleyicisi
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {
            if (!root.useClassicView) {
                root.resetToHome();
            }
        }
    }

    // =========================================================
    // 1. ANA GÖVDE KARTI
    // =========================================================
    // Cam kart: yarı saydam katman + ince kenarlık (gradyan yok). Gölge yok: popup çerçevesinin
    // kendi gölgesi var; ayrıca clip: true kartın gölgesini kutusunda kesip köşeyi köşeli gösteriyordu.
    Rectangle {
        id: bodyCard
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 4
        z: 1

        readonly property int favCount: kickoff.rootModel.favoritesModel ? kickoff.rootModel.favoritesModel.count : 0
        readonly property int favCols: Math.max(1, Math.floor((width - 24) / 90))
        readonly property int favRows: Math.ceil(favCount / favCols)
        // Ana ekranda en fazla bu kadar satır görünür, fazlası kaydırılır (kart popup'ı kaplamasın)
        readonly property int maxVisibleFavRows: 2
        // Alttaki 54px güç düğmesi satırı
        readonly property real fullHeight: root.height - anchors.topMargin - 54
        readonly property real favHeight: Math.min(fullHeight, Math.max(110, Math.min(favRows, maxVisibleFavRows) * 96 + 48))

        // Ana ekran → sekmeler/arama: kart yukarıdan aşağı doğru animasyonla uzar
        height: favHeight + (fullHeight - favHeight) * root.expandProgress

        color: root.st.glass
        radius: root.st.radiusCard
        border.color: root.st.glassBorder
        border.width: root.st.borderWidth
        clip: true

        // ---------------------------------------------------------
        // MOD A: Modern Mod - Tam Dinamik Favoriler Izgarası
        // ---------------------------------------------------------
        Item {
            anchors.fill: parent
            visible: !root.useClassicView && !root.isExpanded

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                PlasmaComponents.Label {
                    text: i18nd("libkicker", "Favorites")
                    font.pointSize: root.st.fontSmall
                    font.weight: Font.DemiBold
                    color: root.st.textMuted
                    Layout.leftMargin: 6
                    Layout.topMargin: 2
                }

                GridView {
                    id: homeFavoritesGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cellWidth: 90
                    cellHeight: 96
                    clip: true
                    model: kickoff.rootModel.favoritesModel
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: PlasmaComponents.ScrollBar {}

                    delegate: Item {
                        id: favDelegate
                        width: homeFavoritesGrid.cellWidth
                        height: homeFavoritesGrid.cellHeight

                        readonly property var view: homeFavoritesGrid
                        readonly property int index: model.index
                        readonly property string favUrl: model.url ?? ""

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: root.st.radiusItem
                            color: favHov.pressed ? root.st.pressed : (favHov.containsMouse ? root.st.hover : "transparent")

                            Behavior on color { ColorAnimation { duration: root.st.durationShort } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Kirigami.Icon {
                                    id: favIconItem
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    source: model.decoration ?? model.icon ?? "application-x-executable"
                                }

                                PlasmaComponents.Label {
                                    Layout.preferredWidth: 80
                                    text: model.display ?? ""
                                    font.pointSize: root.st.fontSmall
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        DragHandler {
                            id: favDragHandler
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                            target: null
                            onActiveChanged: root.performDrag(this, favDelegate, favIconItem, favDelegate.favUrl)
                        }

                        MouseArea {
                            id: favHov
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: favDragHandler.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (favDragHandler.active) return;
                                if (mouse.button === Qt.RightButton) {
                                    root.openNativeActionMenu(favDelegate, model, mouse.x, mouse.y, false);
                                } else {
                                    root.launch(homeFavoritesGrid.model, favDelegate.index);
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------
        // MOD B: Modern Mod - Arama/Sekme Ekranı
        // ---------------------------------------------------------
        RowLayout {
            anchors.fill: parent
            spacing: 0
            visible: !root.useClassicView && root.isExpanded && !root.isSearching
            // Kart uzarken içerik yukarıdan aşağı kayarak ve belirerek gelir
            opacity: root.expandProgress
            transform: Translate { y: -24 * (1 - root.expandProgress) }

            ColumnLayout {
                Layout.preferredWidth: 150
                Layout.minimumWidth: 150
                Layout.maximumWidth: 150
                Layout.fillHeight: true
                spacing: 4
                Layout.margins: 6

                component TabButton: Rectangle {
                    id: btn
                    property string title: ""
                    property string iconName: ""
                    property int tabIndex: 0
                    readonly property bool selected: root.currentTab === tabIndex

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: root.st.radiusItem
                    // Seçili sekme: yumuşak vurgu zemini; hover: nötr ton
                    color: selected ? root.st.accentSoft : (tMouse.containsMouse ? root.st.hover : "transparent")

                    Behavior on color { ColorAnimation { duration: root.st.durationShort } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Kirigami.Icon {
                            source: btn.iconName
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            color: btn.selected ? root.st.accent : Kirigami.Theme.textColor
                        }

                        PlasmaComponents.Label {
                            text: btn.title
                            font.pointSize: root.st.fontSmall
                            font.weight: btn.selected ? Font.DemiBold : Font.Normal
                            // Sekme 150 px: uzun çeviriler (de, ru…) iki satıra iner, sığmazsa kısalır
                            Layout.maximumWidth: btn.width - 18 - 8 - 16
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: tMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = btn.tabIndex
                    }
                }

                TabButton { title: i18nd("libkicker", "All Applications"); iconName: "applications-all"; tabIndex: 0 }
                TabButton { title: i18ndc("plasma_applet_org.kde.plasma.kickoff", "category in Places sidebar", "Frequently Used"); iconName: "view-sort"; tabIndex: 1 }
                TabButton { title: i18nd("libkicker", "Recent Applications"); iconName: "view-history"; tabIndex: 2 }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                Layout.preferredWidth: 1
                color: root.st.divider
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: allAppsGrid
                    anchors.fill: parent
                    anchors.margins: 8
                    visible: root.currentTab === 0
                    cellWidth: 90; cellHeight: 94; clip: true
                    // rootModel satır 0 = favori yer tutucusu, satır 1 = "Tüm Uygulamalar"
                    model: {
                        root.rootModelRevision; // bağımlılık: yenilemede yeniden hesapla
                        return kickoff.rootModel.count > 1 ? kickoff.rootModel.modelForRow(1) : null;
                    }
                    delegate: AppGridItemDelegate { parentView: allAppsGrid; modelRef: allAppsGrid.model }
                }

                GridView {
                    id: mostUsedGrid
                    anchors.fill: parent
                    anchors.margins: 8
                    visible: root.currentTab === 1
                    cellWidth: 90; cellHeight: 94; clip: true
                    model: kickoff.frequentAppsModel
                    delegate: AppGridItemDelegate { parentView: mostUsedGrid; modelRef: mostUsedGrid.model }
                }

                GridView {
                    id: recentGrid
                    anchors.fill: parent
                    anchors.margins: 8
                    visible: root.currentTab === 2
                    cellWidth: 90; cellHeight: 94; clip: true
                    model: kickoff.recentAppsModel
                    delegate: AppGridItemDelegate { parentView: recentGrid; modelRef: recentGrid.model }
                }
            }
        }

        // ---------------------------------------------------------
        // MOD C: Klasik Kickoff Modu - Tam Sayfa
        // ---------------------------------------------------------
        HorizontalStackView {
            id: classicStackView
            anchors.fill: parent
            visible: root.useClassicView && !root.isSearching
            focus: true
            reverseTransitions: root.classicBottomTab === 1

            initialItem: ApplicationsPage {
                id: classicAppsPage
                preferredSideBarWidth: root.defaultSideBarWidth
                width: classicStackView.width
                height: classicStackView.height
            }

            Component {
                id: classicPlacesComponent
                PlacesPage {
                    preferredSideBarWidth: root.defaultSideBarWidth
                    preferredSideBarHeight: classicAppsPage.implicitSideBarHeight
                    width: classicStackView.width
                    height: classicStackView.height
                }
            }

            Connections {
                target: root
                function onClassicBottomTabChanged() {
                    if (!root.useClassicView) return;
                    if (root.classicBottomTab === 0) {
                        classicStackView.replace(classicAppsPage);
                    } else if (root.classicBottomTab === 1) {
                        classicStackView.replace(classicPlacesComponent);
                    }
                }
            }
        }

        // ---------------------------------------------------------
        // MOD D: Arama Sonuçları Listesi
        // Stok Kickoff gibi gruplu: Uygulamalar, sonra konumlar, sonra dosyalar...
        // ---------------------------------------------------------
        ListView {
            id: directSearchView
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            visible: root.isSearching
            clip: true
            currentIndex: 0
            // Kart uzarken içerik yukarıdan aşağı kayarak ve belirerek gelir
            opacity: root.expandProgress
            transform: Translate { y: -24 * (1 - root.expandProgress) }
            model: kickoff.runnerModel.count ? kickoff.runnerModel.modelForRow(0) : null

            section.property: "group"
            section.criteria: ViewSection.FullString
            section.delegate: PlasmaComponents.Label {
                required property string section
                width: directSearchView.width
                topPadding: 8
                bottomPadding: 4
                leftPadding: 12
                text: section
                font.pointSize: root.st.fontSmall
                font.weight: Font.DemiBold
                color: root.st.textMuted
                elide: Text.ElideRight
            }

            delegate: Rectangle {
                id: searchDelegate
                width: directSearchView.width
                height: 52
                radius: root.st.radiusItem

                readonly property var view: directSearchView
                readonly property int index: model.index
                readonly property string searchItemUrl: model.url ?? ""
                // Enter ile açılacak öğe: vurgu rengi sadece burada
                readonly property bool isCurrent: ListView.isCurrentItem

                color: isCurrent ? root.st.accentSoft : (sItemMouse.containsMouse ? root.st.hover : "transparent")
                border.color: isCurrent ? root.st.accentBorder : "transparent"
                border.width: root.st.borderWidth

                Behavior on color { ColorAnimation { duration: root.st.durationShort } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Kirigami.Icon {
                        id: searchIconItem
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        source: model.decoration ?? model.icon ?? "application-x-executable"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: model.display ?? ""
                            font.pointSize: root.st.fontNormal
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: model.description ?? ""
                            font.pointSize: root.st.fontSmall
                            color: root.st.textMuted
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }
                }

                DragHandler {
                    id: sDragHandler
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
                    target: null
                    onActiveChanged: root.performDrag(this, searchDelegate, searchIconItem, searchDelegate.searchItemUrl)
                }

                MouseArea {
                    id: sItemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: sDragHandler.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (sDragHandler.active) return;
                        if (mouse.button === Qt.RightButton) {
                            root.openNativeActionMenu(searchDelegate, model, mouse.x, mouse.y, true);
                        } else {
                            root.launch(directSearchView.model, searchDelegate.index);
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // 2. KICKOFF ORİJİNAL SOL ALT TABBAR (Applications / Places)
    // =========================================================
    Item {
        id: bottomNavArea
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.bottomMargin: 8
        width: 220
        height: 38
        z: 2
        visible: root.useClassicView

        RowLayout {
            anchors.fill: parent
            spacing: 4

            component ClassicTabBtn: Item {
                id: cTab
                property string label: ""
                property string iconName: ""
                property int tabId: 0
                readonly property bool active: root.classicBottomTab === tabId

                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: cTab.active ? root.st.accentSoft : (cTabMouse.containsMouse ? root.st.hover : "transparent")

                    Behavior on color { ColorAnimation { duration: root.st.durationShort } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        source: cTab.iconName
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        color: cTab.active ? root.st.accent : Kirigami.Theme.textColor
                    }

                    PlasmaComponents.Label {
                        text: cTab.label
                        font.pointSize: root.st.fontSmall
                        font.weight: cTab.active ? Font.DemiBold : Font.Normal
                        Layout.maximumWidth: cTab.width - 16 - 6 - 16
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: cTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Arama açıkken sekme gizli kalıyordu: aramayı temizleyip seçilen sekmeye geç
                        if (root.isSearching && kickoff?.searchField) {
                            kickoff.searchField.text = "";
                        }
                        root.classicBottomTab = cTab.tabId;
                    }
                }
            }

            ClassicTabBtn {
                label: i18ndc("plasma_applet_org.kde.plasma.kickoff", "@title:tab kickoff sidebar tab", "Applications")
                iconName: "applications-all"
                tabId: 0
            }

            ClassicTabBtn {
                label: i18ndc("plasma_applet_org.kde.plasma.kickoff", "@title:tab kickoff sidebar tab", "Places")
                iconName: "compass"
                tabId: 1
            }
        }
    }

    Component.onCompleted: {
        kickoff.contentArea = root
    }
}
