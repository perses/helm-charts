#!/bin/sh
# Runs inside the cluster, next to Perses.
set -eu

api=http://perses:8080
json='Content-Type: application/json'

status() {
  curl --silent --output /dev/null --write-out '%{http_code}' "$@"
}

expect() {
  if [ "$2" != "$3" ]; then
    echo "$1: expected HTTP $2, got $3" >&2
    exit 1
  fi
  echo "$1: HTTP $3"
}

sign_up_and_login() {
  expect "sign up $1" 200 "$(status --header "$json" \
    --data "{\"kind\":\"User\",\"metadata\":{\"name\":\"$1\"},\"spec\":{\"nativeProvider\":{\"password\":\"oat-password\"}}}" \
    "$api/api/v1/users")"
  expect "login $1" 200 "$(status --cookie-jar "/tmp/$1" --header "$json" \
    --data "{\"login\":\"$1\",\"password\":\"oat-password\"}" \
    "$api/api/auth/providers/native/login")"
}

create_global_role() {
  status --cookie "/tmp/$1" --header "$json" \
    --data "{\"kind\":\"GlobalRole\",\"metadata\":{\"name\":\"$2\"},\"spec\":{\"permissions\":[]}}" \
    "$api/api/v1/globalroles"
}

expect "anonymous request" 401 "$(status "$api/api/v1/projects")"

sign_up_and_login oat-admin
sign_up_and_login oat-user

expect "authenticated request" 200 "$(status --cookie /tmp/oat-user "$api/api/v1/projects")"
expect "regular user creates a global role" 403 "$(create_global_role oat-user oat-denied)"

# The admin binding is provisioned by the sidecar, so give it a moment to be picked up.
for attempt in $(seq 1 30); do
  code=$(create_global_role oat-admin oat-allowed)
  [ "$code" = 200 ] && break
  sleep 5
done
expect "bootstrapped admin creates a global role" 200 "$code"
