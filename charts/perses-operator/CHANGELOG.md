# Changelog

All notable changes to the perses-operator Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.5.0]

### Added

- Prometheus monitoring integration: ServiceMonitor, PrometheusRule with 6 alerting rules, and metrics-reader ClusterRoleBinding for kube-rbac-proxy authentication.

### Changed

- Bump appVersion to `0.5.0` (perses-operator v0.5.0).
- Bump kube-rbac-proxy from `v0.21.2` to `v0.22.1` (Go 1.26.5, security fixes: html/template XSS, HTTP/2 infinite loop, x/net IDNA).
- Metrics service `app.kubernetes.io/name` label fixed to use chart name (was hardcoded `service`) — required for ServiceMonitor label matching.
- kube-rbac-proxy now uses cert-manager issued TLS certificate when `certManager.enable=true`.
- Metrics service DNS names added to the serving cert.

## [0.4.0]

### Changed

- Align chart version with perses-operator appVersion. Chart version now matches the operator release version.
- Bump appVersion to `0.4.0` (perses-operator v0.4.0).
- Bump kube-rbac-proxy from `v0.21.0` to `v0.21.2`.

## [0.2.1]

### Changed

- Bump appVersion to `0.3.2` (perses-operator v0.3.2).

## [0.2.0]

### Changed

- Bump appVersion to `0.3.1` (perses-operator v0.3.1).
- Sync all CRDs from upstream perses-operator v0.3.1, including new `PersesGlobalDatasource` CRD.
- Generate self-signed TLS certificate when `certManager.enable=false` so the operator webhook server can start without cert-manager.
- CRD conversion webhooks are now conditional on `certManager.enable`.
- Bump kube-rbac-proxy image from `gcr.io/kubebuilder/kube-rbac-proxy:v0.13.1` to `quay.io/brancz/kube-rbac-proxy:v0.21.0` for CVE fixes.

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
