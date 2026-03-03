#!/usr/bin/env bash
#
# Syncs CRDs from the perses-operator repository and wraps them
# with Helm templating directives.
#
# The version is read from appVersion in Chart.yaml.
#
# Usage:
#   ./hack/sync-crds.sh
#
# Approach based on:
#   https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/hack/update_crds.sh

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

if [[ $(uname -s) = "Darwin" ]]; then
  VERSION="$(grep ^appVersion "${SCRIPT_DIR}/../charts/perses-operator/Chart.yaml" | sed 's/appVersion: //g' | tr -d '"')"
else
  VERSION="$(grep ^appVersion "${SCRIPT_DIR}/../charts/perses-operator/Chart.yaml" | sed 's/appVersion:\s//g' | tr -d '"')"
fi
VERSION="v${VERSION#v}"

# destination : source : webhook (yes/no)
FILES=(
  "perses.perses.dev.yaml            : perses.dev_perses.yaml            : yes"
  "persesdashboards.perses.dev.yaml  : perses.dev_persesdashboards.yaml  : yes"
  "persesdatasources.perses.dev.yaml : perses.dev_persesdatasources.yaml : no"
  "persesglobaldatasources.perses.dev.yaml : perses.dev_persesglobaldatasources.yaml : yes"
)

# Helm template snippets (matching upstream 2-space indentation)
HELM_ANNOTATIONS='    {{- if .Values.crd.keep }}
    "helm.sh/resource-policy": keep
    {{- end }}
    {{- if .Values.certManager.enable }}
    cert-manager.io/inject-ca-from: {{ .Release.Namespace }}/{{ include "perses-operator.resourceName" (dict "suffix" "serving-cert" "context" $) }}
    {{- end }}'

WEBHOOK_CONVERSION='  conversion:
    strategy: Webhook
    webhook:
      clientConfig:
        service:
          name: {{ include "perses-operator.resourceName" (dict "suffix" "webhook-service" "context" $) }}
          namespace: {{ .Release.Namespace }}
          path: /convert
      conversionReviewVersions:
        - v1'

for line in "${FILES[@]}"; do
  DESTINATION=$(echo "${line%%:*}" | xargs)
  rest="${line#*:}"
  SOURCE=$(echo "${rest%%:*}" | xargs)
  NEEDS_WEBHOOK=$(echo "${rest##*:}" | xargs)

  URL="https://raw.githubusercontent.com/perses/perses-operator/${VERSION}/config/crd/bases/${SOURCE}"

  echo -e "Downloading Perses Operator CRD with version ${VERSION}:\n${URL}\n"

  echo "# ${URL}" >"${SCRIPT_DIR}/../charts/perses-operator/templates/crd/${DESTINATION}"

  if ! curl --silent --retry-all-errors --fail --location "${URL}" >>"${SCRIPT_DIR}/../charts/perses-operator/templates/crd/${DESTINATION}"; then
    echo -e "Failed to download ${URL}!"
    exit 1
  fi
done

# Wrap downloaded CRDs with Helm templating
for line in "${FILES[@]}"; do
  DESTINATION=$(echo "${line%%:*}" | xargs)
  rest="${line#*:}"
  NEEDS_WEBHOOK=$(echo "${rest##*:}" | xargs)

  FILE="${SCRIPT_DIR}/../charts/perses-operator/templates/crd/${DESTINATION}"
  CONTENT=$(cat "${FILE}")

  {
    echo '{{- if .Values.crd.enable }}'
    while IFS= read -r crd_line; do
      if [[ "${crd_line}" == "---" ]]; then
        continue
      fi

      printf '%s\n' "${crd_line}"

      if [[ "${crd_line}" == "  annotations:" ]]; then
        printf '%s\n' "${HELM_ANNOTATIONS}"
      fi

      if [[ "${NEEDS_WEBHOOK}" == "yes" && "${crd_line}" == "spec:" ]]; then
        printf '%s\n' "${WEBHOOK_CONVERSION}"
      fi
    done <<< "${CONTENT}"
    echo '{{- end }}'
  } > "${FILE}"
done

echo "CRD sync complete. Please review the changes and run 'make helm-validate' to validate."
