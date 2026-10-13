# ro-app-template

Canonical GitHub Template Repository for new Ro-ASD application repositories.

## Purpose

This repository provides the common application governance and release contract for
Project-Ro-ASD. It standardizes the stable CI interface (`ro-app-gate`) and the
Producer V2 release bundle format without granting production trust by itself.

A repository created from this template must replace the placeholders in
`.roasd/app.json` and implement the two project-specific hooks:

- `tools/project-ci`
- `tools/build-rpm`

Until those hooks are implemented, copied application repositories fail closed.

## Stable CI contract

`.github/workflows/ci.yml` always ends in the status check:

    ro-app-gate

Application-specific build, test, lint and validation logic belongs behind
`tools/project-ci`. Organization/repository policy should depend on `ro-app-gate`,
not on internal job names.

## Release contract

`.github/workflows/release.yml` runs only for exact `v*` tags. It:

1. validates `.roasd/app.json`,
2. verifies the tag resolves to the workflow commit,
3. builds Fedora 44 RPMs for the declared architectures through `tools/build-rpm`,
4. verifies package name, version, `.fc44`, architecture and SRPM parity,
5. creates a draft GitHub Release,
6. generates `SHA256SUMS` and `component-artifact-manifest-v1.json`,
7. creates GitHub artifact attestations,
8. verifies the exact release asset set,
9. publishes the release.

The workflow does not contain or receive Ro-ASD production signing private keys.
Production signing remains centralized in Ro-Repo.

## Production trust

Creating a repository from this template, or setting `roasd_type=application`, does
**not** make it an official package producer. Official producer onboarding remains a
reviewed change to:

    Project-Ro-ASD/Ro-Repo/config/producers-v1.yaml

The registry binds the exact repository, allowed package names, architectures,
Fedora release and trusted release workflow.

## Template metadata

The template intentionally contains placeholders:

```json
{
  "component": "__ROASD_COMPONENT__",
  "package_names": ["__ROASD_PACKAGE__"]
}
```

The future Ro-ASD repository bootstrap tool will replace these during repository
creation. Manual users must replace them before application CI can pass.
