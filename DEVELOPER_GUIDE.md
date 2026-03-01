# Developer Guide

This guide covers setting up your local environment, common development tasks, and CI workflows for contributing to the Perses Helm Charts repository.

## Prerequisites

- [Go](https://golang.org/dl/) (for tool installation)
- [Helm](https://helm.sh/docs/intro/install/)
- [Docker](https://docs.docker.com/get-docker/) (for helm-docs generation)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (for local testing)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Tool Management

Tools are managed via `Makefile.tools`. They are installed to the local `bin/` directory and pinned to specific versions.

```bash
make helm         # Install Helm
make mdox         # Install mdox (markdown formatter)
make clean-tools  # Remove all installed tools
```

Tool versions and CI environment variables (Kind, cert-manager) are centralized in `.github/env`.

## Linting and Validation

```bash
make helm-lint       # Run helm lint --strict on all charts
make helm-template   # Render all chart templates
make helm-validate   # Run both lint and template
```

## Testing

### Local Testing with Kind

The Makefile provides targets to spin up a Kind cluster, install cert-manager (required by the operator chart), deploy charts, and run Helm tests.

Test all charts:

```bash
make helm-test
```

Test a single chart:

```bash
make helm-test CHART=charts/perses-operator
```

You can also manage the cluster lifecycle separately:

```bash
make kind-create    # Create kind cluster with cert-manager
# ... manually install and test charts ...
make kind-delete    # Tear down the cluster
```

### CI Testing

The `lint-and-test` workflow runs on every pull request that modifies files under `charts/`. It:

1. Sets up a Kind cluster
2. Installs cert-manager
3. Runs `ct install --all` (chart-testing: installs each chart and runs `helm test`)
4. Validates chart READMEs are up to date

## Syncing CRDs from Upstream

The perses-operator CRDs in `charts/perses-operator/templates/crd/` are sourced from the [perses-operator](https://github.com/perses/perses-operator) repository (`config/crd/bases/`). The script at `hack/sync-crds.sh` follows the same pattern as the [kube-prometheus-stack CRD updater](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/hack/update_crds.sh) -- it downloads each CRD individually and wraps it with the necessary Helm templating:

- `{{- if .Values.crd.enable }}` conditional install
- `helm.sh/resource-policy: keep` annotation (controlled by `crd.keep`)
- `cert-manager.io/inject-ca-from` annotation (controlled by `certManager.enable`)
- Webhook conversion block with templated service name/namespace (for CRDs with multiple versions)

Currently synced CRDs:

| Upstream file                       | Destination                         | Webhook |
|-------------------------------------|-------------------------------------|---------|
| `perses.dev_perses.yaml`            | `perses.perses.dev.yaml`            | yes     |
| `perses.dev_persesdashboards.yaml`  | `persesdashboards.perses.dev.yaml`  | yes     |
| `perses.dev_persesdatasources.yaml` | `persesdatasources.perses.dev.yaml` | no      |

> **Note:** `persesglobaldatasources` is not yet available upstream and is commented out in the script. Uncomment when a future release includes it.

The script reads `appVersion` from `charts/perses-operator/Chart.yaml` to determine which release tag to download from. To sync a different version, update `appVersion` in `Chart.yaml` first.

### Usage

```bash
make sync-crds
```

After syncing, always run `make helm-validate` to ensure the templates still render correctly, and review the diff to verify the Helm wrappers were applied properly.

## Documentation

Chart READMEs are auto-generated using [helm-docs](https://github.com/norwoodj/helm-docs) and formatted with [mdox](https://github.com/bwplotka/mdox).

### Generating Chart READMEs

```bash
make update-helm-readme
```

This runs `helm-docs` (via Docker) for each chart followed by `mdox fmt` to format all markdown files.

### Writing Value Descriptions

Use the `# --` comment style in `values.yaml` so helm-docs picks up descriptions:

```yaml
# -- Enable metrics endpoint
enable: true
```

Each chart has a `README.md.gotmpl` template that controls the generated README structure. Edit the template to change sections like prerequisites, install instructions, etc.

### Checking Docs

```bash
make checkdocs
```

This formats all docs and verifies there are no uncommitted changes to markdown files.

## Adding a New Chart

1. Create the chart under `charts/<chart-name>/`
2. Add a `README.md.gotmpl` template for helm-docs
3. Use `# --` comments in `values.yaml` for value descriptions
4. Add helm tests under `templates/tests/`
5. Run `make update-helm-readme` to generate the README
6. Update `.github/CODEOWNERS` with ownership
7. Update `renovate.json` if the chart tracks an `appVersion` from a container image
8. Run `make helm-validate` and `make helm-test CHART=charts/<chart-name>` to verify
