# Managing authentication secrets

This chart can automatically wire authentication provider `client_id` and `client_secret` values into the Perses pods as environment variables, so you can keep credentials in Kubernetes Secrets instead of the Helm values file.

## How it works

- The chart auto-generates env vars for each provider in `config.security.authentication.providers` (OIDC and OAuth) using the `PERSES_SECURITY_AUTHENTICATION_PROVIDERS_<TYPE>_<INDEX>_CLIENT_ID/CLIENT_SECRET` pattern.
- By default, a Secret is created to hold these env vars. You can also point to an existing Secret.
- Env var keys in the Secret are kebab-cased versions of the env var names (e.g. `perses-security-authentication-providers-oidc-0-client-secret`).

## Using an existing Secret (recommended)

Create a Secret with the expected keys:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oidc-config
stringData:
  perses-security-authentication-providers-oidc-0-client-id: "<client-id>"
  perses-security-authentication-providers-oidc-0-client-secret: "<client-secret>"
```

Reference it in values:

```yaml
config:
  security:
    enable_auth: true
    authentication:
      providers:
        oidc:
          - slug_id: azure
            name: "Azure AD"
            issuer: "https://login.microsoftonline.com/<tenant>/v2.0"
            scopes: ["openid","profile","email","User.read"]
secret:
  create: false
  name: oidc-config
```

## Using the chart-generated Secret

Let the chart create the Secret and optionally set a name:

```yaml
secret:
  create: true
  name: "" # optional; defaults to the release fullname
```

Populate `client_id` / `client_secret` directly in values (or add them via `envVars`), and the chart will place them in the generated Secret and mount them as env vars.

## Providing extra env vars

You can still add custom env vars via `envVars`, which are merged with the auto-generated ones:

```yaml
envVars:
  - name: PERSES_SECURITY_AUTHENTICATION_PROVIDERS_OIDC_0_CLIENT_SECRET
    value: "override-me"
```

## Deprecated: `envVarsExternalSecretName`

`envVarsExternalSecretName` continues to work but is deprecated since 0.19.2 and will be removed in a future release. Prefer the `secret.create` / `secret.name` pattern above.***
