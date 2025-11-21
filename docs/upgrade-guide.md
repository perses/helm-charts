# Perses Helm Chart Upgrade Guide

## Overview

This guide provides instructions for upgrading Perses Helm chart releases, particularly when dealing with breaking changes between versions.

We try as much as possible to avoid breaking changes, but sometimes it's necessary to introduce them. If you are upgrading from a version to another that contains breaking changes, you will need to follow the version-specific steps outlined below.

## Upgrade Types

### Patch Upgrades

For patch version upgrades (e.g., 0.8.0 → 0.8.1), you can typically perform a standard Helm upgrade without special considerations:

```bash
helm upgrade my-release perses/perses
```

### Major/Minor Upgrades with Breaking Changes

For upgrades that introduce breaking changes, follow the version-specific migration guides below.

## Breaking Changes by Version

### Upgrading to 0.18.0

This version introduces breaking changes to the `image` section. Some fields have been added.


#### Configuration Field Changes

- Added `image.registry` to support CRI-O 1.34

**Before:**

```yaml
image:
  name: "persesdev/perses"
```

**After:**

```yaml
image:
  registry: docker.io
  name: "persesdev/perses"
```

### Upgrading to 0.8.0

This version introduces breaking changes to the `config` section. Some fields have been renamed and reorganized.

#### Configuration Field Changes

**Update `security` Fields:**

- Change `readOnly` to `readonly`
- Change `enableAuth` to `enable_auth`

**Before:**

```yaml
security:
  readOnly: false
  enableAuth: false
```

**After:**

```yaml
security:
  readonly: false
  enable_auth: false
```

**Move `important_dashboards` to `frontend` section:**

**Before:**

```yaml
important_dashboards:
- name: "My Dashboard"
    url: "https://my-dashboard.com"
```

**After:**

```yaml
frontend:
  important_dashboards:
  - name: "My Dashboard"
    url: "https://my-dashboard.com"
```

#### Additional Changes

- SQL field is not defined by default anymore
- File system storage is now the default storage mode

#### Migration Steps

1. **Backup your current values:**

   ```bash
   helm get values my-release > backup-values.yaml
   ```

2. **Update your values file** according to the field changes above

3. **Test the upgrade** in a non-production environment first

4. **Perform the upgrade:**

   ```bash
   helm upgrade my-release perses/perses -f updated-values.yaml
   ```

5. **Verify the deployment** is working correctly after upgrade

## General Upgrade Best Practices

1. **Always backup** your current Helm values and any persistent data before upgrading
2. **Review the changelog** for the target version to understand all changes
3. **Test upgrades** in a development or staging environment first
4. **Monitor the application** after upgrade to ensure everything is functioning correctly
5. **Have a rollback plan** ready in case issues arise

## Rollback Procedure

If you encounter issues after upgrading, you can rollback to the previous version:

```bash
# List release history
helm history my-release

# Rollback to previous revision
helm rollback my-release

# Or rollback to specific revision
helm rollback my-release <revision-number>
```
