#!/usr/bin/env python3
"""Ro widget sözleşmesi denetimi (Ro-Theme-Docs 21 · WGT).

Her üst düzey klasör bir Plasma widget'ıdır (metadata.json + contents/). Denetlenenler:
- metadata.json geçerli JSON, KPackageStructure Plasma/Applet, kimlik org.ro.*;
- contents/ui/qmldir varsa klasördeki her .qml orada kayıtlı (WGT-08);
- her .qml/.js dosyasında SPDX lisans başlığı;
- QML'de elle renk yok: hex renk ve Qt.rgba(sayı...) yasak, renkler Kirigami.Theme'den (WGT-03);
- widget paketinde gereksiz tema kopyası (default/) yok (WGT-13);
- metadata.json KPlugin.Version, spec'teki varsayılan sürümle aynı;
- RoTokens.qml varsa Ro-Theme'in ürettiği kopyadır ve Style.qml köşeleri sayı değil token'dır (WGT-02/05).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []

def err(msg):
    errors.append(msg)

widgets = [p for p in ROOT.iterdir() if (p / 'metadata.json').is_file()]
if not widgets:
    err('hiç widget bulunamadı (metadata.json içeren üst düzey klasör yok)')

hex_color = re.compile(r'["\']#[0-9a-fA-F]{3,8}["\']')
rgba_literal = re.compile(r'Qt\.rgba\(\s*[0-9.]+\s*,')

for w in sorted(widgets):
    name = w.name
    try:
        meta = json.loads((w / 'metadata.json').read_text(encoding='utf-8'))
    except json.JSONDecodeError as e:
        err(f'{name}: metadata.json geçersiz: {e}')
        continue
    if meta.get('KPackageStructure') != 'Plasma/Applet':
        err(f'{name}: KPackageStructure Plasma/Applet olmalı')
    pid = meta.get('KPlugin', {}).get('Id', '')
    if not pid.startswith('org.ro.'):
        err(f'{name}: KPlugin.Id org.ro.* olmalı (bulunan: {pid!r})')
    spec = (ROOT / 'packaging' / 'ro-widgets.spec').read_text(encoding='utf-8')
    spec_version = re.search(r'%\{!\?ro_version:([0-9.]+)\}', spec).group(1)
    if meta.get('KPlugin', {}).get('Version') != spec_version:
        err(f'{name}: metadata.json KPlugin.Version ({meta.get("KPlugin", {}).get("Version")}) spec sürümüyle ({spec_version}) aynı olmalı')
    if (w / 'default').exists():
        err(f'{name}: default/ klasörü pakete girmemeli (WGT-13)')
    ui = w / 'contents' / 'ui'
    qmldir = ui / 'qmldir'
    if qmldir.is_file():
        listed = set(re.findall(r'\s(\S+\.qml)\s*$', qmldir.read_text(encoding='utf-8'), re.M))
        for q in ui.glob('*.qml'):
            if q.name not in listed and q.name not in ('main.qml', 'config.qml', 'ConfigGeneral.qml'):
                err(f'{name}: {q.name} qmldir içinde kayıtlı değil (WGT-08)')
    tokens = ui / 'RoTokens.qml'
    if tokens.is_file():
        text = tokens.read_text(encoding='utf-8')
        if 'pragma Singleton' not in text or 'generate-theme.sh' not in text:
            err(f'{name}: RoTokens.qml Ro-Theme çıktısı değil; tools/sync-tokens ile kopyalayın')
        if not qmldir.is_file() or not re.search(r'^singleton RoTokens \S+ RoTokens\.qml$', qmldir.read_text(encoding='utf-8'), re.M):
            err(f'{name}: RoTokens qmldir içinde singleton olarak kayıtlı değil (WGT-08)')
    style = ui / 'Style.qml'
    if style.is_file():
        for i, line in enumerate(style.read_text(encoding='utf-8').splitlines(), 1):
            if re.match(r'\s*readonly property real radius\w*:\s*[0-9.]+\s*$', line):
                err(f'{style.relative_to(ROOT)}:{i}: köşe sayı olarak yazılmış; RoTokens kullanın (WGT-05)')
    for f in sorted(list(w.rglob('*.qml')) + list(w.rglob('*.js'))):
        rel = f.relative_to(ROOT)
        text = f.read_text(encoding='utf-8')
        if 'SPDX-License-Identifier' not in text:
            err(f'{rel}: SPDX lisans başlığı yok')
        if f.suffix == '.qml':
            for i, line in enumerate(text.splitlines(), 1):
                code = line.split('//', 1)[0]
                if hex_color.search(code) or rgba_literal.search(code):
                    err(f'{rel}:{i}: elle renk (WGT-03): {line.strip()}')

for e in errors:
    print(f'[FAIL] {e}')
print(f'widget: {len(widgets)}, hata: {len(errors)}')
sys.exit(1 if errors else 0)
