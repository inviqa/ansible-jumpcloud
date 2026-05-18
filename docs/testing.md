# Test Harness

This document describes the JumpCloud role test harness. Local test operations
run through Workspace, which owns the repository Docker Compose environment.

## Table of Contents

- [Coverage](#coverage)
- [Setup](#setup)
- [Workspace Commands](#workspace-commands)
- [Workspace Compose Environment](#workspace-compose-environment)
- [Container Tests](#container-tests)
- [DigitalOcean Live Tests](#digitalocean-live-tests)
- [Jenkinsfile Lint](#jenkinsfile-lint)
- [Clean Up](#clean-up)
- [Debian 13 Maintenance Check](#debian-13-maintenance-check)
- [Notes](#notes)

## Coverage

The default inventory exercises systemd-enabled container images:

| Family | Default image |
| --- | --- |
| Debian | `geerlingguy/docker-debian12-ansible:latest` |
| Enterprise Linux | `geerlingguy/docker-rockylinux9-ansible:latest` |
| Ubuntu | `geerlingguy/docker-ubuntu2404-ansible:latest` |

The container harness validates support-matrix and dependency-install behavior.
It intentionally does not run the real JumpCloud agent installer because that
device-management agent is not supported inside local Docker containers.

The DigitalOcean harness provisions real droplets for end-to-end validation:

| Family | DigitalOcean image slug |
| --- | --- |
| Debian | `debian-12-x64` |
| Debian unsupported-release validation | `debian-13-x64` |
| Enterprise Linux | `rockylinux-9-x64` |
| Ubuntu | `ubuntu-24-04-x64` |

## Setup

Install the Workspace CLI if `ws` is not already available:

```bash
WS_VERSION=0.4.1
curl --output ./ws --location "https://github.com/my127/workspace/releases/download/${WS_VERSION}/ws"
chmod +x ws && sudo mv ws /usr/local/bin/ws
```

Live commands read local attributes from `workspace.override.yml`. Create it
from the example first:

```text
cp workspace.override.yml.example workspace.override.yml
```

For live tests, fill the DigitalOcean API token, DigitalOcean SSH key selector,
JumpCloud connect key, and JumpCloud API key. The selected DigitalOcean SSH key
must match a private key loaded in the forwarded SSH agent.

## Workspace Commands

The preferred local entrypoint is Workspace:

```text
ws
```

Useful commands:

```text
ws syntax
ws ansible-lint
ws ansible-playbook tests/playbook.yml tests/inventory-docker
ws lint-jenkinsfile
ws test-docker
ws test-live
ws test-live-rocky
ws cleanup-live
```

Both `ws console` and `ws ansible-playbook` load live-test environment values
from `workspace.override.yml` and forward them into the `console` container.
Other Workspace commands compose those entrypoints instead of repeating Docker
environment wiring.

Use `ws syntax` for syntax checks. Internally it calls `ws ansible-playbook`
with the Workspace syntax-check flag.

## Workspace Compose Environment

The repository Docker Compose environment is needed because local tests run from
the same Ansible console container used by Workspace. That console container
also starts and removes the systemd-enabled target containers used by
`ws test-docker`.

To do that without running Ansible as `root`, Workspace resolves the host Docker
socket group ID and passes it to Compose as `HOST_DOCKER_GID`. Compose applies
that numeric ID through `group_add`, which makes it a supplemental group for the
processes started in the `console` container. The commands still run as the
`ansible` user, but they can access the mounted Docker socket.

The root group is also added because Docker Desktop exposes the mounted socket
inside the container as `root:root`. On Linux/Jenkins, the host socket group ID
is the relevant group.

## Container Tests

Run the default container-backed validation:

```text
ws test-docker
```

The command runs the test playbook and then the cleanup playbook, even when the
main playbook fails.

Run syntax-only validation:

```text
ws syntax
```

## DigitalOcean Live Tests

Run the DigitalOcean-backed end-to-end harness:

```text
ws test-live
```

To run one Rocky Linux target locally:

```text
ws test-live-rocky
```

The live playbook:

- creates one small DigitalOcean droplet for each target OS
- waits for SSH
- installs Python if the image needs it
- runs the JumpCloud role
- verifies local agent config and service state
- verifies JumpCloud registration, display name, SSH attributes, and optional
  system-group membership through the JumpCloud API

The DigitalOcean harness runs the role's pre-install duplicate system cleanup by
default so reruns can replace stale records with the same display name. Set
`test.jumpcloud.delete_duplicate_systems` to `false` in `workspace.override.yml`
only when diagnosing the cleanup path separately.

If a DigitalOcean test was interrupted, run cleanup explicitly:

```text
ws cleanup-live
```

## Jenkinsfile Lint

Validate the repository `Jenkinsfile` with the Workspace Jenkins lint controller
and the Jenkins Declarative Pipeline linter:

```text
ws lint-jenkinsfile
```

This command starts the Workspace `console` and `jenkins-lint` Compose services
and runs the helper inside the `console` container.

## Clean Up

DigitalOcean live tests run cleanup automatically. If a live run is interrupted,
remove matching JumpCloud test system records and DigitalOcean droplets with:

```text
ws cleanup-live
```

Container test cleanup is part of `ws test-docker`.

## Debian 13 Maintenance Check

`tests/tasks/unsupported_release_install_identity.yml` is a task file, not a
playbook to run directly. It is included by `tests/playbook.yml` only when the
selected inventory enables the Debian 13 container maintenance check.

Run the isolated maintenance check through the normal test playbook:

```text
ws console
```

Inside the Workspace console:

```text
ansible-playbook -i tests/inventory-docker-debian13 tests/playbook.yml
```

This inventory sets
`jumpcloud_test_validate_unsupported_release_install_identity=true`, so
`tests/playbook.yml` includes
`tests/tasks/unsupported_release_install_identity.yml` during the
container-safe validation phase.

Use this check when changing:

- `jumpcloud_install_on_unsupported_distribution`
- `jumpcloud_supported_linux_versions`
- `jumpcloud_supported_linux_release_identities`
- `tasks/apply_install_os_release_identity.yml`
- `tasks/restore_install_os_release_identity.yml`

The normal end-to-end validation for Debian 13 remains the DigitalOcean target
with `jumpcloud_install_on_unsupported_distribution: true`.

## Notes

- The live-host harness registers real systems in JumpCloud.
- The default container harness does not register containers in JumpCloud.
- The DigitalOcean harness creates billable droplets and deletes droplets tagged
  with `ANSIBLE-JUMPCLOUD-TEST` during cleanup.
- `tests/test_variables.yml` is gitignored and may contain local secrets.
- Test display names and droplets use `ansible-jumpcloud-<target>-test`; if an
  inventory host starts with `jumpcloud-`, that prefix is removed from the
  target suffix.
