# Changelog

All notable changes to the perses-operator Helm chart will be documented in this file.

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
