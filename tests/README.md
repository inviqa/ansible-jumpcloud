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
- [Jenkinsfile Lint](#jenkinsfile-lint)
- [Clean Up](#clean-up)
- [DigitalOcean Live Tests](#digitalocean-live-tests)
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
`tests/inventory-docker-redhat` for supported Enterprise Linux container
testing.

The DigitalOcean harness provisions real droplets for end-to-end validation:

| Family | DigitalOcean image slug |
| --- | --- |
| Debian | `debian-12-x64` |
| Debian unsupported-release validation | `debian-13-x64` |
| Enterprise Linux | `rockylinux-9-x64` |
| Ubuntu | `ubuntu-24-04-x64` |

## Setup

Install test collection dependencies:

```text
ansible-galaxy collection install -r tests/requirements.yml
```

Install Python dependencies required by the DigitalOcean collection in the
Python runtime used by Ansible:

```text
python -m pip install -r tests/requirements.txt
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

For DigitalOcean live tests, also set:

```yaml
do_test_api_token: "dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
do_ssh_keys:
  - "12345678"
# Optional but recommended when your SSH agent has many keys loaded.
# do_ssh_private_key_file: "~/.ssh/id_ed25519"
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
ansible-playbook -i tests/inventory-docker tests/playbook.yml
```

Run one container-backed family only:

```text
ansible-playbook -i tests/inventory-docker-debian tests/playbook.yml
ansible-playbook -i tests/inventory-docker-debian13 tests/playbook.yml
ansible-playbook -i tests/inventory-docker-redhat tests/playbook.yml
ansible-playbook -i tests/inventory-docker-ubuntu tests/playbook.yml
```

Run against live hosts:

```text
ansible-playbook -i tests/inventory-live tests/playbook.yml
```

The live-host run installs the JumpCloud agent and validates registration,
display-name update, and optional system-group membership. The container run
validates the supported-distribution and dependency-install paths without
registering a Docker container as a JumpCloud device.

## DigitalOcean Live Tests

Run the DigitalOcean-backed end-to-end harness:

```text
ansible-playbook -i tests/inventory-digitalocean-droplets tests/playbook.yml
```

This playbook:

- creates one small DigitalOcean droplet for each target OS
- waits for SSH
- installs Python if the image needs it
- runs the JumpCloud role
- verifies the local agent config and service
- verifies JumpCloud registration, display name, SSH attributes, and optional
  system-group membership through the JumpCloud API

The DigitalOcean harness runs the role's pre-install duplicate system cleanup by
default so reruns can replace stale records with the same display name. Set
`jumpcloud_test_delete_duplicate_systems: false` in `tests/test_variables.yml`
only when diagnosing the cleanup path separately.

Always run cleanup after a DigitalOcean test:

```text
ansible-playbook -i tests/inventory-digitalocean-droplets tests/playbook_cleanup.yml
```

Run syntax-only validation:

```text
ansible-playbook -i tests/inventory-docker tests/playbook.yml --syntax-check
```

## Jenkinsfile Lint

Validate the repository `Jenkinsfile` with a temporary Dockerized Jenkins
controller and the Jenkins Declarative Pipeline linter:

```text
tests/lint_jenkinsfile.sh
```

The helper installs only the Jenkins plugins needed by this pipeline into an
isolated temporary Jenkins home, runs the validation endpoint, and removes the
temporary controller after the check finishes.

## Clean Up

Remove matching JumpCloud test system records and any local test containers:

```text
ansible-playbook -i tests/inventory-docker tests/playbook_cleanup.yml
```

If a single-family run fails mid-flight, clean up with the matching inventory
before retrying:

```text
ansible-playbook -i tests/inventory-docker-debian tests/playbook_cleanup.yml
```

If no JumpCloud API key is configured, cleanup skips API record removal and
still removes local test containers. Deleting an active system record through
JumpCloud should also remove the agent and policies from the active device. If
a host is inactive, follow JumpCloud's manual agent removal documentation for
the target distribution.

## Notes

- The live-host harness registers real systems in JumpCloud.
- The default container harness does not register containers in JumpCloud.
- The DigitalOcean harness creates billable droplets and deletes droplets tagged
  with `ANSIBLE-JUMPCLOUD-TEST` during cleanup.
- The Docker replacement for the old `chrismeyersfsu.provision_docker` role is
  the maintained `community.docker.docker_container` module.
- DigitalOcean droplet provisioning uses the maintained `digitalocean.cloud`
  collection, matching the newer Frontdoor Base test infrastructure.
- `tests/test_variables.yml` is gitignored and may contain local secrets.
- The playbook validates the JumpCloud API key before changing target hosts.
- Test display names and droplets use `ansible-jumpcloud-<target>-test`; if an
  inventory host starts with `jumpcloud-`, that prefix is removed from the
  target suffix.
- The role fails early for distributions outside the current JumpCloud support
  matrix unless `jumpcloud_validate_supported_distribution` is disabled.
- The DigitalOcean harness includes a Debian 13 target with
  `jumpcloud_install_on_unsupported_distribution=true` to validate the
  temporary install identity path against a real unsupported release.
