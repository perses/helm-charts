# Managing Perses Resources with ConfigMaps

> [!NOTE]
> This approach is only applicable when Perses is configured to use file system storage (`database.file`).

By default, a sidecar container is deployed in the Perses pod when enabled. This container uses [kiwigrid/k8s-sidecar](https://github.com/kiwigrid/k8s-sidecar) to watch all ConfigMaps in the cluster and filters out the ones with a configurable label (default: `perses.dev/resource: "true"`). 

The files defined in those ConfigMaps are written by the sidecar to a shared volume that is also mounted by the main Perses container at the [provisioning path](https://perses.dev/perses/docs/configuration/provisioning). Changes to the ConfigMaps are continuously monitored by the sidecar and reflected in Perses based on the **provisioning configuration interval** (by default 1 hour).

All Perses manifests such as Dashboards, Projects, Datasources, etc. can be managed as ConfigMaps using this approach.

## How It Works

The ConfigMap-based resource management uses a combination of Kubernetes sidecar pattern and Perses provisioning:

1. **ConfigMaps** → Created with configurable label (configured via `sidecar.label` and `sidecar.labelValue`)
2. **Sidecar Container** → Watches and extracts ConfigMap contents to filesystem
3. **Shared Volume** → Sidecar writes ConfigMap contents to a shared volume mounted by both containers
4. **Perses Provisioning** → Scans the shared volume at configured interval and loads resources into perses file-based database

## Configuration

### Sidecar Configuration

Enable the sidecar in your Helm values:

```yaml
sidecar:
  enabled: true
  label: "perses.dev/resource"
  labelValue: "true"
  allNamespaces: true  # Watch ConfigMaps from all namespaces
```

### Provisioning Timing

The frequency of resource updates is controlled by Perses provisioning configuration, not the sidecar. To configure faster updates, adjust the provisioning interval in your Perses configuration:

```yaml
provisioning:
  interval: "5m"  # Check for changes every 5 minutes instead of default 1 hour
  folders:
    - /etc/perses/provisioning  # Path where the shared volume is mounted
```

## Recommended Folder Structure

When using the custom chart approach, organize your resources in the `files/` directory:

```bash
your-chart/files/
├── dashboards/
│   ├── dashboard1.json
│   ├── dashboard2.json
├── projects/
│   ├── project1.json
│   ├── project2.json
└── datasources/
    ├── prometheus-demo.json
    └── tempo-demo.json
```

## Easy ConfigMap Creation with Helm template

You can use the below Helm template to automatically generate ConfigMaps for all the Perses resources placed in a folder within your Helm chart.

```yaml
# In your custom chart's templates/configmaps.yaml
{{- range $path, $bytes := .Files.Glob "files/**/*.json" }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ printf "%s-%s" $.Release.Name ($path | replace "/" "-" | replace ".json" "") | trunc 63 }}
  labels:
    {{ $.Values.perses.sidecar.label | default "perses.dev/resource" }}: "{{ $.Values.perses.sidecar.labelValue | default "true" }}"
data:
{{ printf "%s: |-" ($path | base) | indent 2 }}
{{ printf "%s" $bytes | indent 4 }}
{{- end }}
```

Place your resources in your chart's `files/` directory:
```bash
your-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   └── configmaps.yaml
└── files/
    ├── dashboards/
    │   └── dashboard1.json
    └── datasources/
        └── prometheus.json
```

## Examples

Below are examples of ConfigMaps for different Perses resources.

### Dashboard ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-dashboard
  labels:
    perses.dev/resource: "true"  # Use your configured sidecar.label and sidecar.labelValue
data:
  dashboard.json: |-
    {
      "kind": "Dashboard",
      "metadata": {
        "name": "my-dashboard",
        "project": "default"
      },
      "spec": {
        "display": {
          "name": "My Dashboard"
        },
        "panels": {
          "panel1": {
            "kind": "Panel",
            "spec": {
              "display": {
                "name": "Sample Panel"
              },
              "plugin": {
                "kind": "TimeSeriesChart",
                "spec": {}
              }
            }
          }
        }
      }
    }
```

### Project ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-project
  labels:
    perses.dev/resource: "true"  # Use your configured sidecar.label and sidecar.labelValue
data:
  project.json: |-
    {
      "kind": "Project",
      "metadata": {
        "name": "my-project"
      },
      "spec": {
        "display": {
          "name": "My Project"
        }
      }
    }
```

## Best Practices

ConfigMaps have a 1MB data limit in Kubernetes. It's recommended to use one resource per ConfigMap to avoid hitting this limit and to make resource management easier.