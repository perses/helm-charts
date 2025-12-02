# Installing Perses with Helm

This guide covers how to install Perses on Kubernetes using Helm charts.

## Prerequisites

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

## Installation

### Add the Perses Helm Repository

Add the Perses Helm repository and update your local repository cache:

```console
helm repo add perses https://perses.github.io/helm-charts
helm repo update
```

### Basic Installation

Install Perses with default configuration:

```console
helm install my-perses perses/perses # my-perses is the release name
```

### Using FluxCD
If you want to use Perses with [FluxCD](https://fluxcd.io/), you can include the Perses manifests directly in your GitOps repository so Flux can reconcile and deploy them automatically.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: perses
  namespace: <namespace>
spec:
  interval: 12h
  url: https://perses.github.io/helm-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: perses
  namespace: <namespace>
spec:
  interval: 1h
  timeout: 5m
  releaseName: perses
  targetNamespace: <namespace>
  chart:
    spec:
      chart: perses
      version: <version>
      sourceRef:
        kind: HelmRepository
        name: perses
        namespace: <namespace>
      interval: 1m

  install:
    createNamespace: true
    remediation:
      retries: 3

  upgrade:
    remediation:
      retries: 3
```
## Verification

After installation, verify that Perses is running:

```console
# Check pod status
kubectl get pods -l app.kubernetes.io/name=my-perses

# Check service
kubectl get svc -l app.kubernetes.io/name=my-perses

# View logs
kubectl logs -l app.kubernetes.io/name=my-perses
```

If you configured an ingress, you should be able to access Perses at your configured hostname. Otherwise, you can port-forward to access the service:

```console
kubectl port-forward svc/my-perses 8080:80
```

Then visit http://localhost:8080 in your browser to access the Perses UI.

## Exposing Perses via Gateway API

Gateway API support is optional and disabled by default. Make sure Gateway API CRDs and a `GatewayClass` are installed in your cluster before enabling it.

### Create a Gateway and HTTPRoute

This creates both resources and wires the route to the created gateway:

```console
helm install my-perses perses/perses \
  --set gateway.enabled=true \
  --set gateway.createGateway=true \
  --set gateway.gatewayClassName=<your-gateway-class> \
  --set gateway.httpRoute.hostnames[0]=perses.example.com
```

Optional overrides:
- `gateway.name` / `gateway.namespace`: name/namespace of the Gateway (defaults to `<release>-perses-gateway` in the release namespace)
- `gateway.listeners`: listener definitions for the Gateway
- `gateway.httpRoute.rules`: custom match/backends; defaults to PathPrefix `/` to the Perses service

### Reuse an existing Gateway (only create HTTPRoute)

If a Gateway already exists, only create the HTTPRoute and point it at that Gateway:

```console
helm install my-perses perses/perses \
  --set gateway.enabled=true \
  --set gateway.createGateway=false \
  --set gateway.httpRoute.parentRefs[0].name=<existing-gateway> \
  --set gateway.httpRoute.parentRefs[0].namespace=<gateway-namespace> \
  --set gateway.httpRoute.hostnames[0]=perses.example.com
```

`gateway.httpRoute.parentRefs` is required when `createGateway=false`; you can also set `sectionName`/`port` if your Gateway needs them.
