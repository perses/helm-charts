{{/* ========================================================================
Configuration helpers
========================================================================= */}}

{{/*
Return env vars generated from authentication providers for client_id/client_secret.
We include entries even when the value is empty so they can be sourced from an external Secret.
*/}}
{{- define "perses.authProviderEnvVars" -}}
{{- $result := list }}
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
{{- toYaml $result }}
{{- end }}

{{/*
Merge user-provided envVars with auto-generated auth provider env vars.
*/}}
{{- define "perses.mergedEnvVars" -}}
{{- $autoEnabled := (default true .Values.autoGenerateAuthEnvVars) }}
{{- $auto := list }}
{{- if $autoEnabled }}
  {{- $auto = (include "perses.authProviderEnvVars" . | fromYaml | default (list)) }}
{{- end }}
{{- $user := .Values.envVars | default (list) }}
{{- $merged := concat $user $auto }}
{{- toYaml $merged }}
{{- end }}

{{/*
Resolve env vars Secret name (generated or custom override).
*/}}
{{- define "perses.envVarsSecretName" -}}
{{- if .Values.envVarsSecretName }}
{{- .Values.envVarsSecretName }}
{{- else }}
{{- include "perses.fullname" . }}
{{- end }}
{{- end }}
