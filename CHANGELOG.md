# CHANGELOG

## [3.0.0] - 2026-05-18 - Galaxy and Linux Support Refresh

### Breaking Changes

- Removed role-internal sudo control. Set `become: true` on the calling play or
  role instead of using `jumpcloud_use_sudo`. See
  [Upgrading to 3.0.0](docs/upgrading-to-3.0.0.md).
- Removed legacy Ubuntu 12 and CentOS 6/7 install behavior. Use currently
  supported Linux releases, or set `jumpcloud_validate_supported_distribution:
  false` only for deliberate tests outside the supported matrix.
- Renamed the documented system attribute variables to snake_case. Existing
  camelCase variables still work in `3.0.0`, but new playbooks should use
  `jumpcloud_display_name`, `jumpcloud_allow_public_key_authentication`,
  `jumpcloud_allow_ssh_password_authentication`, `jumpcloud_allow_ssh_root_login`,
  and `jumpcloud_allow_multi_factor_authentication`.
- Replaced legacy tag terminology with JumpCloud system group terminology. Use
  `jumpcloud_system_groups` for group membership.

### New Capabilities

- Added opt-in installation on newer unsupported releases in otherwise
  supported distribution families by temporarily presenting the latest supported
  `/etc/os-release` identity during the JumpCloud kickstart run, then restoring
  the original file before registration checks.
- Added role-level system-group membership verification immediately after group
  synchronization.
- Added sanitized duplicate-system lookup diagnostics, including status and
  redacted module output, so Jenkins exposes actionable failures without
  leaking JumpCloud data.
- Added a Jenkins pipeline and local Jenkinsfile lint command that run through
  Workspace, use a companion Jenkins controller with the required pipeline
  plugins, and validate with the Jenkins Declarative Pipeline linter.
- Replaced the legacy Docker, Vagrant, and Travis-era test workflow with a
  Workspace-managed test harness with container-safe `community.docker`
  validation and a `digitalocean.cloud` integration path that provisions real
  droplets, applies the role, verifies JumpCloud state, and cleans up resources.

### Platform Support

- Refreshed Galaxy-facing metadata, support claims, maintainer details,
  documentation, and role defaults for current Ansible Galaxy and JumpCloud
  Linux agent expectations.
- Aligned Galaxy metadata with the default-supported runtime matrix instead of
  advertising opt-in or unconstrained platforms.
- Added Fedora 43 to the validated Linux support matrix to match JumpCloud's
  current Linux agent compatibility documentation.
- Advertised Debian 13 as a validated target, with container validation for the
  temporary install identity path and a DigitalOcean live target for
  end-to-end unsupported-release validation, although Debian 13 is not yet
  officially supported by JumpCloud.
- Removed obsolete Ubuntu 12 and CentOS 6/7 behavior and terminology in favor
  of the current supported platform matrix and RedHat-family naming.

### Install and Registration

- Modernized the install path for current Debian, Ubuntu, and RedHat-family
  targets, including cleaner dependency lists, DNF `curl-minimal`
  compatibility, bounded Kickstart execution, non-interactive Debian-family
  installs, and recovery when the installed `jcagent` service must be started
  before `jcagent.conf` is created.
- Extended Debian-family dependency installation while preserving DNF minimal
  package compatibility for `coreutils-single` and `curl-minimal`.
- Preserved original `/etc/os-release` symlink structure when restoring after
  unsupported-release install identity overrides.
- Fixed JumpCloud registration delegation.
- Kept registration checks bounded while allowing a persistent missing system
  record to be reported as unregistered instead of failing before
  reconciliation.
- Removed role-internal privilege escalation, disabled `become` for localhost
  JumpCloud API tasks, and removed the role-specific `jumpcloud_use_sudo`
  switch; callers now run the role as a privileged user or set Ansible
  `become: true`.

### Role Structure

- Reworked the role task layout so `tasks/main.yml` is an orchestration entry
  point, registered-system reconciliation is separated from installation, and
  group synchronization plus verification live in focused task files.
- Reorganized test playbooks and duplicate-system cleanup into focused task
  files so playbooks and role entrypoints act as orchestration layers.
- Cleaned up YAML and Ansible task structure for linting, readability, and
  publication readiness.

### Security and Secret Handling

- Hardened secret handling so JumpCloud API keys, connect keys, API response
  bodies, and request headers stay out of task output and failed-test logs.
- Serialized and retried duplicate-system JumpCloud API cleanup calls to avoid
  transient live-test failures while keeping API responses, request headers,
  returned device data, and secrets hidden from logs.
- Hardened Workspace console command dispatch so pass-through commands execute
  as tokenized container arguments instead of shell-evaluated strings.

### Test Harness and CI

- Standardized local validation on Workspace commands using the published
  multi-arch `quay.io/inviqa_images/ansible:2.20-python3.13-trixie` image,
  forwarded SSH agent and Docker socket access, and gitignored
  `workspace.override.yml` attributes for live-test credentials.
- Centralized Workspace command execution through `ws enable`, `ws console`,
  and `ws ansible-playbook <playbook> <inventory>` so Compose setup,
  environment forwarding, and playbook execution are not duplicated across
  wrappers.
- Kept Workspace playbook execution under the `ansible` container user and used
  Compose `group_add` with the host Docker socket GID for Docker access instead
  of mutating users or groups during container startup.
- Moved the controller Python interpreter selection into `local` group vars so
  localhost tasks use the Ansible runtime Python without play-level overrides.
- Split DigitalOcean live-test provisioning into reusable SSH key resolution,
  SSH agent validation, droplet provisioning, and SSH access task files.
- Disabled inherited SSH proxy settings for DigitalOcean live-test droplets so
  the test harness connects directly to the provisioned public hosts.
- Renamed test inventories and normalized DigitalOcean droplet names so Docker
  and DigitalOcean targets are explicit and the `ansible-jumpcloud` prefix is
  applied only once.
- Grouped repeated test-harness conditions into clearer blocks, removed an
  avoidable command-module dependency check from container validation, and
  renamed public variables to snake case while preserving legacy camelCase
  compatibility.
- Fixed live Jenkins test SSH credential binding so the shared SSH-agent helper
  receives the configured shared Ansible roles credential ID explicitly.
- Fixed the live-test role symlink so Jenkins can resolve the role from a
  job-named workspace instead of requiring an `ansible-jumpcloud` parent
  directory.
- Restored failure-only Jenkins Slack notifications after live-test remediation.
- Moved Jenkins credential IDs, Slack notification controls, and runtime values
  into the top-level pipeline environment block.

### Documentation

- Moved test harness documentation into `docs/testing.md`, documented the
  Workspace CLI install path and Compose environment model, and updated
  repository agent instructions so Ansible and Jenkinsfile linting run through
  Workspace.
- Clarified the test procedure with the copy-paste Workspace CLI install command
  required before running `ws` test commands.
- Added Mermaid flowcharts for the DigitalOcean live-test cleanup path and the
  Jenkins live-test pipeline.
- Added a README link to the repository changelog so release history is easier
  to find.
- Added an upgrade guide for users moving from `2.4.1` to `3.0.0`.
- Grouped the 3.0.0 release notes by scope so the major capabilities,
  platform updates, test harness changes, documentation updates, and fixes are
  easier to scan.

## [2.4.1] - 2022-04-12

- Added retry handling while reading the JumpCloud agent `systemKey` from
  `jcagent.conf`, avoiding transient install failures when the agent had not
  finished writing the key yet.
- Increased the lookup window to five attempts with a three-second delay so a
  first role run can complete instead of requiring a manual rerun.

## [2.4.0]

- Ansible-lint adjustments.
- Ansible requirements pinning for testing environment.
- Removed package installation loops.
- Made the JumpCloud dependencies organization more organic.

## [2.3.0]

- Ansible requirements pinning for testing environment.
- Removed package installation loops.
- Made the JumpCloud dependencies organization more organic.

## [2.2.0]

- Verified if a system is correctly registered in JumpCloud.
- Automated deletion of previously registered servers with the same name in
  JumpCloud.
- Automated deletion of registered servers in JumpCloud for testing cleanup.
- Removed support for Ubuntu 12.04 testing.

## [2.1.0]

- Replaced Vagrant testing with Docker testing.
- Added test tasks and playbook to test on Debian stable, Ubuntu 12.04, Ubuntu
  14.04, Ubuntu 16.04, Ubuntu 18.04, CentOS 6, and CentOS 7.
- Added Travis CI testing.

## [2.0.0]

- Implemented API v2 task to handle system groups.
- Removed support for tags after they were converted to groups.
- Added a conditional check to add systems to groups only when system groups are
  defined in `jumpcloud_system_groups`.
