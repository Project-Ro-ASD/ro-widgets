#!/usr/bin/env python3
import json
import os
from pathlib import Path

CONFIG = Path('.roasd/app.json')
REQUIRED_ARCHES = {'x86_64', 'aarch64'}


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    data = json.loads(CONFIG.read_text(encoding='utf-8'))
    if data.get('schema_version') != 1:
        fail('schema_version must be 1')
    if data.get('fedora_release') != 44:
        fail('fedora_release must be 44 for Ro-ASD v1')
    if data.get('trusted_release_workflow') != '.github/workflows/release.yml':
        fail('trusted_release_workflow must remain .github/workflows/release.yml')

    arches = set(data.get('architectures') or [])
    if not arches or not arches.issubset(REQUIRED_ARCHES):
        fail('architectures must contain x86_64 and/or aarch64 only')

    packages = data.get('package_names') or []
    if not packages or any(not isinstance(item, str) or not item for item in packages):
        fail('package_names must contain at least one non-empty package name')

    component = data.get('component')
    if not isinstance(component, str) or not component:
        fail('component must be a non-empty string')

    repository = os.environ.get('GITHUB_REPOSITORY', '')
    is_template = repository == 'Project-Ro-ASD/ro-app-template'
    placeholders = [component, *packages]
    if not is_template and any(value.startswith('__ROASD_') for value in placeholders):
        fail('template placeholders must be replaced before application CI can pass')

    print('Ro-ASD application metadata contract: OK')


if __name__ == '__main__':
    main()
