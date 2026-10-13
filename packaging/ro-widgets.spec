Name:           ro-widgets
Version:        %{?ro_version}%{!?ro_version:0.1.0}
Release:        1%{?dist}
Summary:        Ro Desktop Plasma widgets
License:        GPL-3.0-or-later AND GPL-2.0-or-later AND LGPL-2.0-or-later
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
done

%files
%{_datadir}/plasma/plasmoids/org.ro.launcher

%changelog
* Tue Oct 13 2026 Project Ro-ASD - 0.1.0-1
- ro-launcher imported from the developer's working copy
