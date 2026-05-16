# Ansible Role: JumpCloud

Install and configure the JumpCloud Linux agent on supported Linux systems.

This role installs the agent, registers the host with JumpCloud, updates core
system SSH attributes, and optionally adds the system to JumpCloud system
groups.

## Table of Contents

- [Overview](#overview)
- [Current Behavior Notes](#current-behavior-notes)
- [Requirements](#requirements)
- [Installation](#installation)
- [Variables](#variables)
- [Supported Linux Matrix](#supported-linux-matrix)
- [Examples](#examples)
- [Testing](#testing)
- [Maintenance](#maintenance)
- [Jenkins CI](#jenkins-ci)
- [Development Notes](#development-notes)
- [Maintainer](#maintainer)
- [Support](#support)
- [Repository](#repository)
- [License](#license)

## Overview

The role is intentionally focused on Linux agent lifecycle tasks:

- install current JumpCloud Linux agent dependencies
- download the official JumpCloud kickstart installer
- register the target host with a JumpCloud connect key
- remove duplicate JumpCloud system records with the same display name when
  enabled
- update system SSH authentication attributes through the JumpCloud API
- add the system to existing JumpCloud system groups, or create missing groups
  when explicitly enabled

## Current Behavior Notes

- Preferred terminology in this repo is **system groups**. JumpCloud's older
  tag terminology is no longer used by the role.
- JumpCloud API keys and connect keys are high-sensitivity secrets and should be
  provided through Ansible Vault, environment variables, or the gitignored test
  variables file.
- The role validates the target host against JumpCloud's current Linux support
  matrix by default. Set `jumpcloud_validate_supported_distribution: false`
  only when deliberately testing outside the supported matrix.
- For deliberate live validation of a newer release in an otherwise supported
  distribution family, set `jumpcloud_install_on_unsupported_distribution: true`
  so the installer temporarily uses the latest supported release identity and
  restores the original `/etc/os-release` before continuing.
- Debian 13 is validated by this role, but JumpCloud's installer still requires
  `jumpcloud_install_on_unsupported_distribution: true` on that release so the
  install can temporarily present the latest JumpCloud-supported Debian
  identity.
- CentOS is not currently listed in JumpCloud's Linux agent support matrix.
  For Enterprise Linux testing, use supported RHEL or Rocky Linux releases.

## Requirements

- Ansible Core 2.16 or newer
- a supported Linux target host with administrator or sudo access
- outbound HTTPS access to JumpCloud agent endpoints
- a JumpCloud connect key for agent registration
- a JumpCloud API key for duplicate cleanup, attribute updates, registration
  checks, and system group membership
- the `community.docker` collection and local Docker service for the default
  container-backed test harness
- the `digitalocean.cloud` collection, a DigitalOcean API token, and a
  DigitalOcean SSH key for the end-to-end cloud test harness

The role follows the current JumpCloud Linux agent documentation:

- [Install the Linux Agent](https://jumpcloud.com/support/install-the-linux-agent)
- [Agent Compatibility, System Requirements, and Impacts](https://jumpcloud.com/support/agent-compatibility-system-requirements-and-impacts)

## Installation

Current local development role name:

```text
ansible-jumpcloud
```

Intended Ansible Galaxy role name:

```text
inviqa.jumpcloud
```

The repository is being prepared for refreshed Ansible Galaxy publication. Until
that release exists, consume it from a local checkout or a pinned Git reference.

## Variables

| Variable | Default | Notes |
| --- | --- | --- |
| `jumpcloud_x_connect_key` | `{{ enc_jumpcloud_x_connect_key \| default('') }}` | JumpCloud connect key used by the kickstart installer. |
| `jumpcloud_api_key` | `{{ enc_jumpcloud_api_key \| default('') }}` | JumpCloud API key used for system API operations. |
| `jumpcloud_directory` | `/opt/jc` | JumpCloud agent installation directory. |
| `jumpcloud_x_connect_url` | `https://kickstart.jumpcloud.com/Kickstart` | Official JumpCloud Linux kickstart URL. |
| `jumpcloud_install_timeout_seconds` | `300` | Maximum runtime for the JumpCloud kickstart script. |
| `jumpcloud_registration_timeout_seconds` | `180` | Maximum wait for the agent config after starting `jcagent`. |
| `jumpcloud_registration_check_retries` | `18` | Maximum JumpCloud API registration lookup attempts before treating a missing system as unregistered. |
| `jumpcloud_registration_check_delay_seconds` | `10` | Delay between JumpCloud API registration lookup attempts. |
| `jumpcloud_agent_service` | `jcagent` | JumpCloud agent service name. |
| `jumpcloud_force_install` | `false` | Force the install path even when the agent config exists. |
| `jumpcloud_use_sudo` | `false` | Run system-level tasks with privilege escalation. |
| `jumpcloud_validate_supported_distribution` | `true` | Fail early on Linux releases outside the role's current JumpCloud support matrix. |
| `jumpcloud_install_on_unsupported_distribution` | `false` | Temporarily present unsupported releases as the latest supported release in the same distribution family during the JumpCloud kickstart install, then restore `/etc/os-release`. |
| `jumpcloud_delete_duplicate_systems` | `true` | Remove existing JumpCloud systems with the same `displayName` before install. |
| `jumpcloud_display_name` | `{{ inventory_hostname }}` | Display name to set for the JumpCloud system. |
| `jumpcloud_allow_public_key_authentication` | `true` | JumpCloud SSH public key authentication setting. |
| `jumpcloud_allow_ssh_password_authentication` | `true` | JumpCloud SSH password authentication setting. |
| `jumpcloud_allow_ssh_root_login` | `true` | JumpCloud SSH root login setting. |
| `jumpcloud_allow_multi_factor_authentication` | `false` | JumpCloud SSH MFA setting. |
| `jumpcloud_system_groups` | undefined | Optional list of JumpCloud system group names. |
| `jumpcloud_create_missing_system_groups` | `false` | Create missing requested system groups before membership updates. |

## Supported Linux Matrix

This role's defaults track the current JumpCloud Linux agent compatibility
documentation for supported distributions. The practical focus for current
testing is:

| Family | Current supported targets |
| --- | --- |
| Debian | Debian 11, Debian 12, Debian 13 with `jumpcloud_install_on_unsupported_distribution: true` |
| Ubuntu | Ubuntu 18.04, 20.04, 22.04, 24.04, 26.04 |
| Enterprise Linux | RHEL 8, RHEL 9, Rocky Linux 8, Rocky Linux 9 |
| Fedora | Fedora 40, 41, 42 |
| Amazon Linux | Amazon Linux 2, 2023 |
| Oracle Linux | Oracle Linux 9 |

Debian 13 is validated through the role's unsupported-release install path
because JumpCloud's published compatibility list does not yet include it. Keep
`jumpcloud_install_on_unsupported_distribution: true` enabled for Debian 13
until JumpCloud publishes native support.

CentOS 6 and 7 are intentionally no longer advertised because JumpCloud has
ended support for those releases. CentOS Stream is not listed in JumpCloud's
current Linux support matrix, so this role does not claim CentOS Stream support.
Use RHEL or Rocky Linux for current Enterprise Linux validation.

## Examples

```yaml
---
- name: Install JumpCloud on supported Linux hosts
  hosts: linux_devices
  become: true
  roles:
    - role: inviqa.jumpcloud
      vars:
        jumpcloud_use_sudo: true
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

For local checkout testing before Galaxy publication, use the local role name
`ansible-jumpcloud`.

## Testing

[tests/README.md](tests/README.md) documents the current test workflow. The
default inventory provisions local Docker containers with `community.docker` to
validate support-matrix and dependency-install behavior. For release confidence,
run the same playbook against real supported Linux hosts or the
DigitalOcean-backed inventory. DigitalOcean provisioning uses the maintained
`digitalocean.cloud` collection, matching the newer Frontdoor Base pattern.

Fast local validation before live testing:

```text
ansible-playbook -i tests/inventory-docker tests/playbook.yml --syntax-check
tests/lint_jenkinsfile.sh
ansible-galaxy collection install -r tests/requirements.yml
ansible-lint .
yamllint .
markdownlint -c ~/.markdownlint.json AGENTS.md README.md CHANGELOG.md TODO.md tests/README.md
```

End-to-end cloud validation:

```text
ansible-playbook -i tests/inventory-digitalocean-droplets tests/playbook.yml
ansible-playbook -i tests/inventory-digitalocean-droplets tests/playbook_cleanup.yml
```

## Maintenance

`tests/tasks/unsupported_release_install_identity.yml` is a task file, not a
playbook to run directly. It is included by `tests/playbook.yml` only when the
selected inventory enables the Debian 13 container maintenance check. The
current entrypoint for that check is `tests/inventory-docker-debian13`.

This is a maintainer test for the Debian 13 install workaround, not an operator
workflow. It exercises only the temporary `/etc/os-release` override and
restore path, without contacting JumpCloud or provisioning cloud infrastructure.

Use this test when changing:

- `jumpcloud_install_on_unsupported_distribution`
- `jumpcloud_supported_linux_versions`
- `jumpcloud_supported_linux_release_identities`
- `tasks/apply_install_os_release_identity.yml`
- `tasks/restore_install_os_release_identity.yml`

Run the isolated maintenance test from the role root through the normal test
playbook:

1. Install the test collections if they are not already available.

   ```text
   ansible-galaxy collection install -r tests/requirements.yml
   ```

2. Run the normal test playbook with the Debian 13 container inventory.

   ```text
   ansible-playbook -i tests/inventory-docker-debian13 tests/playbook.yml
   ```

   This inventory sets
   `jumpcloud_test_validate_unsupported_release_install_identity=true`, so
   `tests/playbook.yml` includes
   `tests/tasks/unsupported_release_install_identity.yml` during the
   container-safe validation phase.

3. Check the expected result.

   The play recap should show `jumpcloud-debian13` with `failed=0`. During the
   run, the test applies the temporary Debian 12 identity, verifies it, restores
   the original Debian 13 `/etc/os-release`, and verifies that the temporary
   backup file has been removed.

4. If the test fails, inspect only the unsupported-release identity tasks first.

   The failing task usually points to one of these files:
   `tasks/apply_install_os_release_identity.yml`,
   `tasks/restore_install_os_release_identity.yml`, or
   `tests/tasks/unsupported_release_install_identity.yml`.

The normal end-to-end validation for Debian 13 remains the DigitalOcean test
target with `jumpcloud_install_on_unsupported_distribution: true`. That live
path verifies the full role behavior: dependencies, Kickstart execution,
JumpCloud registration, `/etc/os-release` restoration, service state, and
system group membership.

Run the full Debian 13 live test when changing the install flow itself:

```text
ansible-playbook -i tests/inventory-digitalocean-droplets tests/playbook.yml --limit jumpcloud-debian13
ansible-playbook -i tests/inventory-digitalocean-droplets tests/playbook_cleanup.yml --limit jumpcloud-debian13
```

## Jenkins CI

[docs/jenkins-ci.md](docs/jenkins-ci.md) documents the private Jenkins pipeline,
required credential placeholders, Jenkinsfile lint helper, and live-test command
sequence.

## Development Notes

- `AGENTS.md` defines strict repository linting and documentation rules for AI
  coding agents.
- `.ansible/` is generated dependency/cache output and should not be committed.
- `tests/test_variables.yml` is gitignored and may hold local live-test secrets.
- Keep the role support matrix aligned with JumpCloud's published Linux agent
  compatibility list before publishing a new Galaxy release.

## Maintainer

- Author: Marco Massari Calderone `<marco@marcoctu.com>`
- Copyright holder: Inviqa UK Ltd

## Support

For current maintenance and publication work, contact the maintainer above. If
the role is published publicly, issue-tracking and support paths should be
documented alongside the published source.

## Repository

- Public repository URL: pending refreshed publication metadata
- Publication status: pending Ansible Galaxy refresh

## License

MIT
