Name:           ro-widgets
Version:        %{?ro_version}%{!?ro_version:0.1.2}
Release:        1%{?dist}
Summary:        Ro Desktop Plasma widgets
License:        GPL-3.0-or-later AND GPL-2.0-or-later AND LGPL-2.0-or-later AND CC-BY-SA-4.0
URL:            https://github.com/Project-Ro-ASD/ro-widgets
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       plasma-workspace

%description
Plasma widgets of Ro Desktop. ro-launcher is the application launcher of the Ro panel;
Ro-Theme uses it when it is installed and falls back to Kickoff otherwise.

%prep
%autosetup

%build

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

%files
%{_datadir}/plasma/plasmoids/org.ro.launcher
%{_datadir}/icons/hicolor/scalable/apps/ro-start.svg

%changelog
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
