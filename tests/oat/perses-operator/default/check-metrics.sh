#!/bin/sh
# Runs inside the cluster. The first argument is a token allowed to read metrics.
set -eu

url=https://perses-operator-controller-manager-metrics-service:8082/metrics

code=$(curl --insecure --silent --output /dev/null --write-out '%{http_code}' "$url")
if [ "$code" != 401 ]; then
  echo "request without token: expected HTTP 401, got $code" >&2
  exit 1
fi
echo "request without token: HTTP $code"

curl --insecure --silent --show-error --fail --header "Authorization: Bearer $1" "$url" | grep controller_runtime_reconcile_total
