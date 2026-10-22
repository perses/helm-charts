# Managing the encryption key

The official [Perses Helm chart](https://github.com/perses/helm-charts) can mount an encryption key from a Kubernetes Secret into the Perses pod, so you can keep the key out of the Helm values file.

## How it works

- Set `config.security.encryption_key_file` to the path where Perses reads the key.
- Store the key in a Kubernetes Secret under the `encryption_key` key. The decoded key must be exactly 32 bytes.
- Mount the Secret so the key file is available at the configured path.

## Using a Kubernetes Secret

Create a Secret with the expected key. Values under `data` must be base64-encoded:

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