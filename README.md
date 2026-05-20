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
- [Upgrade Guide](#upgrade-guide)
- [Variables](#variables)
- [Supported Linux Matrix](#supported-linux-matrix)
- [Examples](#examples)
- [Testing](#testing)
- [Jenkins CI](#jenkins-ci)
- [Publishing](#publishing)
- [Development Notes](#development-notes)
- [Changelog](#changelog)
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

After the `3.0.2` Galaxy import is complete, install the pinned release with:

```bash
ansible-galaxy role install inviqa.jumpcloud,3.0.2
```

Until that import exists, consume the role from a local checkout or a pinned Git
reference.

## Upgrade Guide

Version `3.0.0` is a major release. Existing `2.4.1` users should review
[Upgrading to 3.0.0](docs/upgrading-to-3.0.0.md) before changing their pinned
role version.

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
| Ubuntu | Ubuntu 18.04, 20.04, 22.04, 24.04, 26.04; Galaxy metadata advertises currently known release codenames only |
| Enterprise Linux | RHEL 8, RHEL 9, RHEL 10, Rocky Linux 8, Rocky Linux 9 |
| Fedora | Fedora 40, 41, 42, 43 |
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

Run this role as a privileged user or set `become: true` in the calling
playbook. Tasks delegated to `localhost` force `become: false` so controller-side
API calls do not depend on local privilege escalation.

## Examples

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

For local checkout testing before Galaxy publication, use the local role name
`ansible-jumpcloud`.

## Testing

The current test workflow is documented in [docs/testing.md](docs/testing.md).
It covers Workspace commands, container tests, DigitalOcean live tests,
Jenkinsfile lint, cleanup, the Workspace CLI install command, and the Debian 13
maintenance check.

## Jenkins CI

[docs/jenkins-ci.md](docs/jenkins-ci.md) documents the private Jenkins pipeline,
required credential IDs and bindings, Jenkinsfile lint helper, and live-test
command sequence.

## Publishing

[docs/ansible-galaxy-release.md](docs/ansible-galaxy-release.md) documents the
GitHub release and Ansible Galaxy import runbook. Maintainers can inspect the
available publication commands with:

```bash
ws ansible-galaxy
```

After the GitHub release and tag exist on `main`, import the role into Galaxy
with:

```bash
ws github release check
ws ansible-galaxy publish
```

The commands use `github.api_token` and `ansible.galaxy.token` from
`workspace.override.yml`, or `GITHUB_TOKEN` and `ANSIBLE_GALAXY_TOKEN` from the
shell environment.

Jenkins can also create the GitHub release and import the role into Galaxy from
the `main` branch with separate publication environment values. See
[docs/jenkins-ci.md](docs/jenkins-ci.md) for the required Jenkins credentials
and publication controls.

## Development Notes

- `AGENTS.md` defines strict repository linting and documentation rules for AI
  coding agents.
- `.ansible/` is generated dependency/cache output and should not be committed.
- `tests/test_variables.yml` is gitignored and may hold local live-test secrets.
- Keep the role support matrix aligned with JumpCloud's published Linux agent
  compatibility list before publishing a new Galaxy release.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Maintainer

- Author: Marco Massari Calderone `<marco@marcoctu.com>`
- Copyright holder: Inviqa UK Ltd

## Support

For current maintenance and publication work, contact the maintainer above. If
the role is published publicly, issue-tracking and support paths should be
documented alongside the published source.

## Repository

- Public repository URL: <https://github.com/inviqa/ansible-jumpcloud>
- Ansible Galaxy role: <https://galaxy.ansible.com/ui/standalone/roles/inviqa/jumpcloud/>
- Publication status: pending `3.0.2` Ansible Galaxy refresh

## License

MIT
