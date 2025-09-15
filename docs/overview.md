# Perses Helm Charts

You can deploy the Perses application in your Kubernetes cluster using the official Helm charts.

## Quick Start

For installation instructions, see the [Installation Guide](installation.md).

## Configuration

The Perses Helm chart allows you to configure the Perses application through your `values.yaml` file. The `config` section in your values file maps directly to the Perses configuration structure.

### How Configuration Works

Any configuration option from the [Perses Configuration Documentation](https://perses.dev/perses/docs/configuration/configuration/) can be set under the `config` key in your Helm values:

```yaml
# values.yaml
config:
  security:
    enable_auth: true
    readonly: false
  database:
    file:
      folder: "/var/lib/perses"
  authentication:
    providers:
      oidc:
        - slug_id: "github"
          name: "Github"
          issuer: "https://github.com"
          client_id: "your-client-id"
          client_secret: "your-client-secret"
```

This configuration structure mirrors exactly what you would put in a Perses configuration file, making it easy to adapt existing Perses configurations to Helm deployments.

For the complete list of available configuration options, refer to the [Perses Configuration Documentation](https://perses.dev/perses/docs/configuration/configuration/).

## Features

### Resource Management

The Helm chart supports two powerful approaches for managing Perses resources:

- **[managing resources with ConfigMaps](managing-resources-with-configmaps.md)**: Use Kubernetes ConfigMaps with a sidecar container to automatically provision dashboards, datasources, and other Perses resources
- **[packaging resources as OCI artifacts](packaging-resources-as-oci-artifacts.md)**: Package and version your Perses resources as OCI artifacts for immutable deployments with rollback capabilities