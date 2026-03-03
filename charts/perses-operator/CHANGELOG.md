# Changelog

All notable changes to the perses-operator Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0]

### Changed

- Bump appVersion to `0.3.0` (perses-operator v0.3.0).
- Sync all CRDs from upstream perses-operator v0.3.0, including new `PersesGlobalDatasource` CRD.
- Generate self-signed TLS certificate when `certManager.enable=false` so the operator webhook server can start without cert-manager.
- CRD conversion webhooks are now conditional on `certManager.enable`.

### Deprecated

- CRD API version `perses.dev/v1alpha1` is deprecated in favor of `perses.dev/v1alpha2`. Existing v1alpha1 resources are automatically converted via the conversion webhook when cert-manager is enabled. Users should migrate their manifests to `v1alpha2`.

## [0.1.1]

### Fixed

- Chart fails to install when `certManager.enable=false` due to unconditional cert volume and volumeMounts in the manager deployment.

### Added

- `values.schema.json` for Helm values validation and Artifact Hub schema display.
- CI and unit test coverage for `certManager.enable=false`.
- Documentation for installing without cert-manager in README.

### Changed

- Webhook cert volume and volumeMounts are now conditional on `certManager.enable`.

## [0.1.0]

- Initial chart release.
