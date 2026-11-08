# Managing the encryption key

The official [Perses Helm chart](https://github.com/perses/helm-charts#perses) can mount an encryption key from a Kubernetes Secret into the Perses pod, so you can keep the key out of the Helm values file.

## How it works

- Set `config.security.encryption_key_file` to the path where Perses reads the key.
- Store the key in a Kubernetes Secret under any key name (this guide uses `encryption_key`). The name only has to match the `subPath` of the volume mount.
- Mount the Secret so the key file is available at the configured path.

> **Warning:** Perses reads the key file as-is and requires exactly 32 bytes. A trailing newline (e.g. from `echo` or a text editor) makes the key 33 bytes long and Perses fails to start with `encryption_key size must be 32 bytes, got 33 bytes`.

## Using a Kubernetes Secret

The easiest way to create a valid key is to let `kubectl` create the Secret. `openssl rand -hex 16` produces exactly 32 characters without a trailing newline:

```sh
kubectl create secret generic perses-encryption-key \
  --from-literal=encryption_key=$(openssl rand -hex 16)
```

Note that `openssl rand -base64 32` produces a 44-byte value, which Perses rejects.

Alternatively, create the Secret from a manifest. Values under `data` must be base64-encoded:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: perses-encryption-key
type: Opaque
data:
  encryption_key: <base64-encoded-32-byte-encryption-key>
```

## Configuring the Helm chart

Set `encryption_key_file` to the mount path in the chart values:

```yaml
config:
  security:
    encryption_key_file: /etc/perses/encryption_key
```

Mount the Secret so its `encryption_key` entry appears at the configured path:

```yaml
volumes:
  - name: perses-encryption-key
    secret:
      secretName: perses-encryption-key
volumeMounts:
  - name: perses-encryption-key
    mountPath: /etc/perses/encryption_key
    subPath: encryption_key
```

## Alternative: using an environment variable

Perses also reads the key from the `PERSES_SECURITY_ENCRYPTION_KEY` environment variable. This cannot be combined with `encryption_key_file`, so leave `config.security.encryption_key_file` unset when using it.

If you already use an existing Secret for authentication providers (see [Managing authentication secrets](auth-secrets.md)), you can add the key to that Secret instead of creating a second Secret with its own volume and mount:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oidc-config
stringData:
  perses-security-authentication-providers-oidc-0-client-id: "<client-id>"
  perses-security-authentication-providers-oidc-0-client-secret: "<client-secret>"
  perses-security-encryption-key: "<32-byte-encryption-key>"
```

Reference the env var in the chart values. The chart reads its value from the Secret key with the kebab-cased name:

```yaml
secret:
  create: false
  name: oidc-config
envVars:
  - name: PERSES_SECURITY_ENCRYPTION_KEY
```

## Rotating the key

- **Restart required:** Perses reads the key only at startup, and a `subPath` mount [does not receive Secret updates](https://kubernetes.io/docs/concepts/configuration/secret/). A key rotated by tools like External Secrets Operator or SOPS takes effect only after the Perses pods are restarted.
- **Existing secrets become unreadable:** Perses encrypts Secrets and GlobalSecrets stored in its database with this key. After changing the key, Perses can no longer decrypt the existing ones, and datasources that use them stop working until those secrets are recreated.
