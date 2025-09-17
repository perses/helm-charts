# Package Perses Resources as OCI Artifacts

!!! note
    This approach is only applicable when Perses is configured to use file system storage (`config.database.file`).

The OCI artifacts feature allows you to package and distribute Perses resources (dashboards, datasources, projects, etc.) as versioned OCI artifacts. This leverages [Kubernetes's ImageVolume feature](https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes/) to mount OCI images directly as volumes, enabling immutable configuration deployments with built-in versioning and rollback capabilities.

## Benefits

- **Version Control**: Distribute dashboards and other Perses resources as immutable, versioned OCI artifacts
- **Rollback Capability**: Easy rollback to previous versions of the perses resources by changing the image tag
- **Large data support**: Overcome ConfigMap size limitations by using OCI artifacts

## Prerequisites

- **Kubernetes**: v1.31 or later
- **Feature Gate**: `ImageVolume` feature gate must be enabled on your cluster
- **Storage Mode**: Only available with file-based storage (StatefulSet deployment)

## Creating OCI Artifacts

Below is an example Dockerfile to create an OCI artifact containing Perses resources. You can customize the paths and contents as needed.

```dockerfile
# Use minimal scratch image for smallest footprint
FROM scratch

# Add metadata labels
LABEL maintainer="your-team"
LABEL description="Perses resources OCI artifact"
LABEL source="your-repository-url"

# Copy all configuration files
COPY dashboards/ /dashboards/
COPY datasources/ /datasources/
COPY projects/ /projects/

# Set working directory
WORKDIR /

# No CMD needed as this is a data-only image
```

## Integration with Provisioning

The OCI artifacts feature integrates seamlessly with Perses' existing provisioning feature:

### Provisioning Configuration in `values.yaml`

Ensure your `provisioning.folders` includes the mount path, which should match the `mountPath` configured in `ociArtifacts`.

```yaml
config:
  provisioning:
    folders:
      - /etc/perses/provisioning  # This path must match ociArtifacts.mountPath
    interval: 10m

# Enable OCI artifacts (disabled by default)
ociArtifacts:
  name: perses-resources
  image:
    reference: "registry.example.com/perses-resources:v1.0.0"
    pullPolicy: IfNotPresent  # Options: Always, IfNotPresent, Never
  mountPath: "/etc/perses/provisioning"  # Must match provisioning.folders path
```

You can check out the [Provisioning Documentation](https://perses.dev/perses/docs/configuration/provisioning/) for more details.

## Use Cases and Workflows

### GitOps Workflow

1. **Development**: Create/modify dashboards in your Git repository
2. **CI/CD Pipeline**: Automatically build and push OCI artifacts on changes

   ```bash
   docker build -t registry.company.com/perses-resources:v1.2.0 .
   docker push registry.company.com/perses-resources:v1.2.0
   ```
3. **Deployment**: Update Helm values with new image tag

   ```bash
   helm upgrade perses ./perses --set ociArtifacts.image.reference=registry.company.com/perses-resources:v1.2.0
   ```
4. **Rollback**: Revert to previous image tag if issues occur

   ```bash
   helm upgrade perses ./perses --set ociArtifacts.image.reference=registry.company.com/perses-resources:v1.1.0
   ```

### Multi-Environment Deployment

```yaml
# Production
ociArtifacts:
  name: perses-prod-config
  image:
    reference: "registry.company.com/perses-resources:prod-v1.2.0"
  mountPath: "/etc/perses/provisioning"
  subPath: "prod"

# Staging
ociArtifacts:
  name: perses-staging-config
  image:
    reference: "registry.company.com/perses-resources:staging-v1.3.0-rc1"
  mountPath: "/etc/perses/provisioning"
  subPath: "staging"
```
