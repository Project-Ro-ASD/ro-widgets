Name:           ro-widgets
Version:        %{?ro_version}%{!?ro_version:0.1.3}
Release:        1%{?dist}
Summary:        Ro Desktop Plasma widgets
License:        GPL-3.0-or-later AND GPL-2.0-or-later AND LGPL-2.0-or-later AND CC-BY-SA-4.0
URL:            https://github.com/Project-Ro-ASD/ro-widgets
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

# Widget'lara özgü çeviriler (<widget>/po/*.po) derlenir; Kickoff'tan gelen metinler KDE'nin kataloglarından.
BuildRequires:  gettext
BuildRequires:  python3

Requires:       plasma-workspace
# Dolphin/masaüstü sağ tık menüsü (Ro Launcher kategorisine ekle): Python betiği, kdialog, busctl
Requires:       python3
Requires:       kdialog
Requires:       systemd

%description
Plasma widgets of Ro Desktop. ro-launcher is the application launcher of the Ro panel;
Ro-Theme uses it when it is installed and falls back to Kickoff otherwise.

%prep
%autosetup

%build
# <widget>/po/<dil>.po -> locale/<dil>/LC_MESSAGES/plasma_applet_<kimlik>.mo
for dir in */; do
  dir="${dir%/}"
  [ -f "$dir/metadata.json" ] && [ -d "$dir/po" ] || continue
  id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$dir/metadata.json")"
  for po in "$dir"/po/*.po; do
    lang="$(basename "$po" .po)"
    install -d "locale/$lang/LC_MESSAGES"
    msgfmt -c -o "locale/$lang/LC_MESSAGES/plasma_applet_$id.mo" "$po"
  done
done
python3 tools/desktop-i18n.py ro-launcher/po ro-launcher/servicemenu/ro-launcher-add-to-category.desktop \
  ro-launcher-add-to-category.desktop

%install
# Her üst düzey widget klasörü (metadata.json içeren) bir plasmoid paketidir; kimliği metadata'dan.
for dir in */; do
  dir="${dir%/}"
  [ -f "$dir/metadata.json" ] || continue
  id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$dir/metadata.json")"
  install -d "%{buildroot}%{_datadir}/plasma/plasmoids/$id"
  cp -a "$dir/metadata.json" "$dir/contents" "%{buildroot}%{_datadir}/plasma/plasmoids/$id/"
  # Widget simgeleri hicolor'a: her ikon temasının yedeği, panel ve widget seçici adıyla bulur.
  for icon in "$dir"/icons/*.svg; do
    [ -f "$icon" ] || continue
    install -Dm0644 "$icon" "%{buildroot}%{_datadir}/icons/hicolor/scalable/apps/$(basename "$icon")"
  done
done
if [ -d locale ]; then
  install -d "%{buildroot}%{_datadir}/locale"
  cp -a locale/. "%{buildroot}%{_datadir}/locale/"
fi
install -Dm0755 ro-launcher/servicemenu/ro-launcher-add-to-category \
  "%{buildroot}%{_libexecdir}/ro-widgets/ro-launcher-add-to-category"
install -Dm0644 ro-launcher-add-to-category.desktop \
  "%{buildroot}%{_datadir}/kio/servicemenus/ro-launcher-add-to-category.desktop"
%find_lang plasma_applet_org.ro.launcher

%files -f plasma_applet_org.ro.launcher.lang
%{_datadir}/plasma/plasmoids/org.ro.launcher
%{_datadir}/icons/hicolor/scalable/apps/ro-start.svg
%dir %{_libexecdir}/ro-widgets
%{_libexecdir}/ro-widgets/ro-launcher-add-to-category
%{_datadir}/kio/servicemenus/ro-launcher-add-to-category.desktop

%changelog
* Tue Oct 20 2026 Project Ro-ASD - 0.1.3-1
- ro-launcher is translated in the 62 languages Kickoff supports (KDE catalogues
  plus its own for the Ro-only strings and the widget description).
- User categories: own application categories below the favourites (home view,
  and in Places of the classic view) that hold applications, files and folders;
  managed from the header menu; setting "Show custom categories".
- Dolphin and desktop right-click menu: add to a Ro Launcher category or to the
  favourites (service menu, /usr/libexec/ro-widgets).
- Home view: favourites and categories scroll together, the scroll bar sits in
  the popup margin; grid cells share the row width; default popup size follows
  the screen (60% height, 34% width of the available area).
- Fixes: popup colours (search field border, power menu, dialog) no longer read
  black; Remove from Category for files with spaces; power menu hover.

* Tue Oct 20 2026 Project Ro-ASD - 0.1.2-1
- Republished as an immutable release so Ro-Repo can accept it; no
  functional changes since 0.1.1.

* Sat Oct 17 2026 Project Ro-ASD - 0.1.1-1
- ro-launcher ships its own icon, ro-start (the Ro logo rings), installed to
  hicolor; it replaces start-here and the KDE logo fallback.
- Release workflow: build-rpm installs rpm-build, first-release detection and
  asset upload fixed.

* Thu Oct 15 2026 Project Ro-ASD - 0.1.0-1
- First release: ro-launcher, the application launcher of the Ro panel
  (Plasma Kickoff based), imported from the developer's working copy.
- Corner radii from the Ro tokens (RoTokens.qml copied into the widget).
- Popup fits the screen at large scales; tile labels follow the font size.
- noarch release.
