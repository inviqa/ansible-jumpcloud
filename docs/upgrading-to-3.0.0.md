# Upgrading to 3.0.0

This guide covers the practical changes required when upgrading from
`inviqa.jumpcloud` `2.4.1` to `3.0.0`.

## Upgrade Summary

Most existing playbooks can upgrade with small changes:

- run the role with Ansible privilege escalation instead of `jumpcloud_use_sudo`
- provide a JumpCloud API key when using registration checks, system attribute
  updates, duplicate cleanup, or system group membership
- use current supported Linux releases, or explicitly opt out of support
  validation for deliberate tests
- prefer the new snake_case variables, while existing camelCase system attribute
  variables continue to work

## Required Changes

### Privilege Escalation

The role no longer manages privilege escalation through `jumpcloud_use_sudo`.
Run the role as a privileged user or enable Ansible `become` in the calling
playbook.

Before:

```yaml
---
- hosts: linux_devices
  roles:
    - role: inviqa.jumpcloud
      vars:
        jumpcloud_use_sudo: true
        jumpcloud_x_connect_key: "{{ vault_jumpcloud_x_connect_key }}"
```

After:

```yaml
---
- hosts: linux_devices
  become: true
  roles:
    - role: inviqa.jumpcloud
      vars:
        jumpcloud_x_connect_key: "{{ vault_jumpcloud_x_connect_key }}"
```

### JumpCloud API Key

Set `jumpcloud_api_key` or `enc_jumpcloud_api_key` when the role needs to check
registration state, update system SSH attributes, remove duplicate registered
systems, or manage system group membership.

```yaml
---
- hosts: linux_devices
  become: true
  roles:
    - role: inviqa.jumpcloud
      vars:
        jumpcloud_x_connect_key: "{{ vault_jumpcloud_x_connect_key }}"
        jumpcloud_api_key: "{{ vault_jumpcloud_api_key }}"
```

## Variable Compatibility

The preferred public variables now use snake_case:

| 2.4.1 variable | 3.0.0 preferred variable |
| --- | --- |
| `jumpcloud_displayName` | `jumpcloud_display_name` |
| `jumpcloud_allowPublicKeyAuthentication` | `jumpcloud_allow_public_key_authentication` |
| `jumpcloud_allowSshPasswordAuthentication` | `jumpcloud_allow_ssh_password_authentication` |
| `jumpcloud_allowSshRootLogin` | `jumpcloud_allow_ssh_root_login` |
| `jumpcloud_allowMultiFactorAuthentication` | `jumpcloud_allow_multi_factor_authentication` |

The old camelCase variables still work in `3.0.0`, so they do not need to be
renamed immediately. Prefer the snake_case names for new playbooks.

If older playbooks followed legacy tag wording, use system group terminology:

```yaml
---
jumpcloud_system_groups:
  - production-linux
```

## Platform Support Changes

Version `3.0.0` validates hosts against the current JumpCloud Linux agent
support matrix by default.

- Ubuntu 12 behavior was removed.
- CentOS 6 and CentOS 7 behavior was removed.
- Current Enterprise Linux testing should use supported RHEL or Rocky Linux
  releases.
- Debian 13 validation is available through the unsupported-release install
  identity path until JumpCloud publishes native Debian 13 support.

For deliberate testing outside the supported matrix, set:

```yaml
---
jumpcloud_validate_supported_distribution: false
```

For newer releases in an otherwise supported distribution family where the
JumpCloud installer needs a supported `/etc/os-release` identity, set:

```yaml
---
jumpcloud_install_on_unsupported_distribution: true
```

## Recommended Upgrade Checklist

1. Pin the current role version in your requirements file before testing.
2. Update playbooks to use `become: true` instead of `jumpcloud_use_sudo`.
3. Ensure `jumpcloud_api_key` or `enc_jumpcloud_api_key` is available where the
   role reconciles JumpCloud state.
4. Replace any legacy `jumpcloud_tags` usage with `jumpcloud_system_groups`.
5. Confirm target hosts are in the supported Linux matrix, or set an explicit
   validation override for deliberate tests.
6. Run the role first against a non-production JumpCloud system or disposable
   test host.

## Example Upgraded Playbook

```yaml
---
- name: Install JumpCloud on supported Linux hosts
  hosts: linux_devices
  become: true
  roles:
    - role: inviqa.jumpcloud
      vars:
        jumpcloud_x_connect_key: "{{ vault_jumpcloud_x_connect_key }}"
        jumpcloud_api_key: "{{ vault_jumpcloud_api_key }}"
        jumpcloud_display_name: "{{ inventory_hostname }}"
        jumpcloud_system_groups:
          - production-linux
        jumpcloud_allow_public_key_authentication: true
        jumpcloud_allow_ssh_password_authentication: false
        jumpcloud_allow_ssh_root_login: false
        jumpcloud_allow_multi_factor_authentication: true
```
