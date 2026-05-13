# Test Harness

This directory contains the integration harness for the JumpCloud Linux agent
role. The default workflow provisions local Docker containers with
`community.docker`, replacing the old `chrismeyersfsu.provision_docker` role
dependency. A live-host inventory is also provided for final validation on real
supported Linux systems.

## Contents

- [Coverage](#coverage)
- [Setup](#setup)
- [Run the Tests](#run-the-tests)
- [Clean Up](#clean-up)
- [Notes](#notes)

## Coverage

The default inventory exercises systemd-enabled container images:

| Family | Default image |
| --- | --- |
| Debian | `geerlingguy/docker-debian12-ansible:latest` |
| Enterprise Linux | `geerlingguy/docker-rockylinux9-ansible:latest` |
| Ubuntu | `geerlingguy/docker-ubuntu2404-ansible:latest` |

The container harness is useful for repeatable role testing, support-matrix
checks, and package-path validation. It intentionally does not run the real
JumpCloud agent installer because that device-management agent is not supported
inside local Docker containers and can hang the container runtime. Final release
validation should run against real hosts using `tests/inventory-live.example` as
the template.

Current recommended live-test targets:

| Family | Recommended host versions |
| --- | --- |
| Debian | Debian 12 |
| Enterprise Linux | RHEL 9 or Rocky Linux 9 |
| Ubuntu | Ubuntu 24.04 or Ubuntu 26.04 |

CentOS-specific inventories are intentionally removed. Use
`tests/inventory-redhat` for supported Enterprise Linux testing.

## Setup

Install test collection dependencies:

```text
ansible-galaxy collection install -r tests/requirements.yml
```

The default inventory provisions local containers through Docker. For live-host
testing, copy the example inventory and populate it with reachable hosts:

```text
cp tests/inventory-live.example tests/inventory-live
```

```ini
[jumpcloud_debian]
debian12 ansible_host=203.0.113.10 ansible_user=root

[jumpcloud_test_hosts:vars]
jumpcloud_test_provision_containers=false
jumpcloud_test_run_agent_install=true
```

Copy the local variables example and edit it:

```text
cp tests/test_variables.example.yml tests/test_variables.yml
```

Set the JumpCloud credentials:

```yaml
jumpcloud_test_x_connect_key: "your-jumpcloud-connect-key"
jumpcloud_test_api_key: "your-jumpcloud-api-key"
```

Environment variables take precedence for CI or one-off local runs:

```text
export JUMPCLOUD_X_CONNECT_KEY="your-jumpcloud-connect-key"
export JUMPCLOUD_API_KEY="your-jumpcloud-api-key"
```

Optional system groups can be configured in `tests/test_variables.yml`:

```yaml
jumpcloud_test_system_groups:
  - ansible_test_1
  - ansible_test_2
jumpcloud_test_create_missing_system_groups: false
```

## Run the Tests

From the repository root, run the default container-backed validation:

```text
ansible-playbook -i tests/inventory tests/playbook.yml
```

Run one container-backed family only:

```text
ansible-playbook -i tests/inventory-debian tests/playbook.yml
ansible-playbook -i tests/inventory-redhat tests/playbook.yml
ansible-playbook -i tests/inventory-ubuntu tests/playbook.yml
```

Run against live hosts:

```text
ansible-playbook -i tests/inventory-live tests/playbook.yml
```

The live-host run installs the JumpCloud agent and validates registration,
display-name update, and optional system-group membership. The container run
validates the supported-distribution and dependency-install paths without
registering a Docker container as a JumpCloud device.

Run syntax-only validation:

```text
ansible-playbook -i tests/inventory tests/playbook.yml --syntax-check
```

## Clean Up

Remove matching JumpCloud test system records and any local test containers:

```text
ansible-playbook -i tests/inventory tests/playbook_cleanup.yml
```

If a single-family run fails mid-flight, clean up with the matching inventory
before retrying:

```text
ansible-playbook -i tests/inventory-debian tests/playbook_cleanup.yml
```

If no JumpCloud API key is configured, cleanup skips API record removal and
still removes local test containers. Deleting an active system record through
JumpCloud should also remove the agent and policies from the active device. If
a host is inactive, follow JumpCloud's manual agent removal documentation for
the target distribution.

## Notes

- The live-host harness registers real systems in JumpCloud.
- The default container harness does not register containers in JumpCloud.
- The Docker replacement for the old `chrismeyersfsu.provision_docker` role is
  the maintained `community.docker.docker_container` module.
- `tests/test_variables.yml` is gitignored and may contain local secrets.
- The playbook validates the JumpCloud API key before changing target hosts.
- Test display names use `ansible-jumpcloud-<inventory_hostname>-test`.
- The role fails early for distributions outside the current JumpCloud support
  matrix unless `jumpcloud_validate_supported_distribution` is disabled.
