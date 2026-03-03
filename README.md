# Perses Kubernetes Helm Charts

Helm charts for provisioning Perses and the Perses Operator on Kubernetes.

## Quick Start

### Prerequisites

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Add the Perses Helm repository:

```console
helm repo add perses https://perses.github.io/helm-charts
helm repo update
```

### Perses

This chart deploys a [Perses](https://github.com/perses/perses) instance on Kubernetes. It provisions a StatefulSet (file-based storage) or Deployment (SQL-backed), along with service, ingress, Gateway API support, TLS, persistence, provisioning sidecar, and optional ServiceMonitor for Prometheus scraping.

Install Perses with default configuration:

```console
helm install my-perses perses/perses
```

For detailed configuration options, see the [Perses chart documentation](./charts/perses/README.md).

### Perses Operator

This chart deploys the [Perses Operator](https://github.com/perses/perses-operator) on Kubernetes. It installs the operator along with CRDs, RBAC, cert-manager integration, and webhook configuration to manage Perses instances, dashboards, and data sources declaratively via custom resources.

Install the Perses Operator with default configuration (requires [cert-manager](https://cert-manager.io/docs/installation/) in the cluster):

```console
helm install perses-operator perses/perses-operator
```

To install without cert-manager (not recommended for production):

```console
helm install perses-operator perses/perses-operator --set certManager.enable=false
```

For detailed configuration options, see the [Perses Operator chart documentation](./charts/perses-operator/README.md).

## Development

See the [Developer Guide](./DEVELOPER_GUIDE.md) for local setup, testing, documentation generation, and adding new charts.

## Contributing

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->

We'd love to have you contribute! Please refer to our [contribution guidelines](https://github.com/perses/helm-charts/blob/main/CONTRIBUTING.md) for details.

## License

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->

[Apache 2.0 License](./LICENSE).
