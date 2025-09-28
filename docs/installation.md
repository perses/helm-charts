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
