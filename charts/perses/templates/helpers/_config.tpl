{{/* ========================================================================
Configuration helpers
========================================================================= */}}

{{/*
Return env vars generated from authentication providers for client_id/client_secret.
We include entries even when the value is empty so they can be sourced from an external Secret.
NOTE: When using external secrets (secret.create=false or envVarsExternalSecretName), 
this should return empty to avoid duplicate secret creation.
*/}}
{{- define "perses.authProviderEnvVars" -}}
{{- $result := list }}
{{- $usingExternalSecret := or (and .Values.secret (not (default true .Values.secret.create))) .Values.envVarsExternalSecretName }}
{{- if not $usingExternalSecret }}
{{- $auth := .Values.config.security.authentication }}
{{- if and .Values.config.security.enable_auth $auth }}
  {{- range $i, $provider := $auth.providers.oidc }}
    {{- $result = append $result (dict "name" (printf "PERSES_SECURITY_AUTHENTICATION_PROVIDERS_OIDC_%d_CLIENT_ID" $i) "value" ($provider.client_id | default "")) }}
    {{- $result = append $result (dict "name" (printf "PERSES_SECURITY_AUTHENTICATION_PROVIDERS_OIDC_%d_CLIENT_SECRET" $i) "value" ($provider.client_secret | default "")) }}
  {{- end }}
  {{- range $i, $provider := $auth.providers.oauth }}
    {{- $result = append $result (dict "name" (printf "PERSES_SECURITY_AUTHENTICATION_PROVIDERS_OAUTH_%d_CLIENT_ID" $i) "value" ($provider.client_id | default "")) }}
    {{- $result = append $result (dict "name" (printf "PERSES_SECURITY_AUTHENTICATION_PROVIDERS_OAUTH_%d_CLIENT_SECRET" $i) "value" ($provider.client_secret | default "")) }}
  {{- end }}
{{- end }}
{{- end }}
{{- toYaml $result }}
{{- end }}

{{/*
Merge user-provided envVars with auto-generated auth provider env vars.
Auto-generated env vars are only added if not already provided by the user.
*/}}
{{- define "perses.mergedEnvVars" -}}
{{- $auto := (include "perses.authProviderEnvVars" . | fromYaml | default (list)) }}
{{- $auto := (kindIs "slice" $auto | ternary $auto (list $auto)) }}
{{- $userRaw := .Values.envVars | default (list) }}
{{- $user := (kindIs "slice" $userRaw | ternary $userRaw (list $userRaw)) }}
{{- /* Build a map of user-provided env var names for deduplication */ -}}
{{- $userEnvNames := dict }}
{{- range $user }}
  {{- if and (kindIs "map" .) (hasKey . "name") }}
    {{- $_ := set $userEnvNames .name true }}
  {{- end }}
{{- end }}
{{- /* Only add auto-generated env vars if not already provided by user */ -}}
{{- $filteredAuto := list }}
{{- range $auto }}
  {{- if and (kindIs "map" .) (hasKey . "name") }}
    {{- if not (hasKey $userEnvNames .name) }}
      {{- $filteredAuto = append $filteredAuto . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $merged := concat $user $filteredAuto }}
{{- if $merged }}
{{- toYaml $merged }}
{{- else }}
[]
{{- end }}
{{- end }}

{{/*
Resolve env vars Secret name (generated or custom override).
*/}}
{{- define "perses.envVarsSecretName" -}}
{{- $name := "" }}
{{- if and .Values.secret .Values.secret.name }}
  {{- $name = .Values.secret.name }}
{{- else if .Values.envVarsExternalSecretName }}
  {{- $name = .Values.envVarsExternalSecretName }}
{{- else }}
  {{- $name = (include "perses.fullname" .) }}
{{- end }}
{{- $name }}
{{- end }}

{{/*
Should we create the env vars Secret?
*/}}
{{- define "perses.shouldCreateEnvVarsSecret" -}}
{{- $create := true }}
{{- if hasKey .Values "secret" }}
  {{- if hasKey .Values.secret "create" }}
    {{- $create = .Values.secret.create }}
  {{- end }}
{{- end }}
{{- $shouldCreate := and $create (not .Values.envVarsExternalSecretName) }}
{{- if $shouldCreate }}true{{- else }}false{{- end }}
{{- end }}
