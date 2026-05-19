# CHANGELOG

## [3.0.0] - 2026-05-18 - Galaxy and Linux Support Refresh

### Breaking Changes

- Removed role-internal sudo control. Set `become: true` on the calling play or
  role instead of using `jumpcloud_use_sudo`. See
  [Upgrading to 3.0.0](docs/upgrading-to-3.0.0.md).
- Removed legacy Ubuntu 12 and CentOS 6/7 install behavior.
- Renamed the documented system attribute variables to snake_case. Existing
  camelCase variables still work in `3.0.0`, but new playbooks should use
  `jumpcloud_display_name`, `jumpcloud_allow_public_key_authentication`,
  `jumpcloud_allow_ssh_password_authentication`, `jumpcloud_allow_ssh_root_login`,
  and `jumpcloud_allow_multi_factor_authentication`.
- Replaced legacy tag terminology with JumpCloud system group terminology. Use
  `jumpcloud_system_groups` for group membership.

### New Capabilities

- Added opt-in installation on newer unsupported releases in otherwise
  supported distribution families using a temporary `/etc/os-release` identity.
- Added role-level system-group membership verification after synchronization.
- Added sanitized duplicate-system diagnostics for actionable Jenkins failures
  without leaking JumpCloud data.
- Added a Workspace-backed Jenkins pipeline and local Jenkinsfile lint command.
- Added Workspace Ansible Galaxy publication commands for `publish`, `status`,
  and `info`.
- Added Workspace GitHub release commands to check and publish the latest
  concrete changelog release.
- Added optional Jenkins release-publication stages for `main` that separately
  create a GitHub release from `CHANGELOG.md` and import the role into Ansible
  Galaxy.
- Replaced the legacy Docker, Vagrant, and Travis-era test workflow with a
  Workspace-managed container and DigitalOcean integration harness.

### Platform Support

- Refreshed Galaxy-facing metadata, support claims, maintainer details,
  documentation, and role defaults for current Ansible Galaxy and JumpCloud
  Linux agent expectations.
- Updated Galaxy role description and discovery tags for installation,
  registration, SSH, MFA, and identity management use cases.
- Aligned Galaxy metadata with the default-supported runtime matrix.
- Added Fedora 43 to the validated Linux support matrix to match JumpCloud's
  current Linux agent compatibility documentation.
- Advertised Debian 13 as a validated target using the unsupported-release
  install identity path, although Debian 13 is not yet officially supported by
  JumpCloud.
- Removed obsolete Ubuntu 12 and CentOS 6/7 behavior and terminology in favor
  of the current supported platform matrix and RedHat-family naming.

### Install and Registration

- Modernized the install path for current Debian, Ubuntu, and RedHat-family
  targets, including dependency cleanup, bounded Kickstart execution, and
  non-interactive Debian-family installs.
- Preserved DNF minimal package compatibility for `coreutils-single` and
  `curl-minimal`.
- Preserved original `/etc/os-release` symlink structure when restoring after
  unsupported-release install identity overrides.
- Fixed JumpCloud registration delegation.
- Kept registration checks bounded and report persistent missing system records
  as unregistered.
- Removed role-internal privilege escalation and disabled `become` for
  localhost JumpCloud API tasks.

### Role Structure

- Reworked the role task layout so `tasks/main.yml` is an orchestration entry
  point, registered-system reconciliation is separated from installation, and
  group synchronization plus verification live in focused task files.
- Reorganized test playbooks and duplicate-system cleanup into focused task
  files.
- Cleaned up YAML and Ansible task structure for linting and publication
  readiness.

### Security and Secret Handling

- Hardened secret handling so JumpCloud API keys, connect keys, API response
  bodies, and request headers stay out of task output and failed-test logs.
- Serialized and retried duplicate-system JumpCloud API cleanup calls to avoid
  transient live-test failures while keeping returned data hidden from logs.
- Hardened Workspace console command dispatch so pass-through commands execute
  as tokenized container arguments instead of shell-evaluated strings.

### Test Harness and CI

- Waited for JumpCloud API reads to reflect updated system SSH attributes before
  live-test validation continues, avoiding transient Jenkins mismatches after a
  successful system update.
- Standardized local validation on Workspace commands using the published
  multi-arch Ansible image with SSH agent and Docker socket forwarding.
- Centralized Workspace command execution through `ws enable`, `ws console`,
  and `ws ansible-playbook <playbook> <inventory>`.
- Kept Workspace playbook execution under the `ansible` container user and
  configured Docker socket access through Compose.
- Moved controller Python interpreter selection into `local` group vars.
- Split DigitalOcean live-test provisioning into focused reusable task files.
- Disabled inherited SSH proxy settings for DigitalOcean live-test droplets.
- Renamed test inventories and normalized DigitalOcean droplet names so Docker
  and DigitalOcean targets are explicit.
- Grouped repeated test-harness conditions, removed an avoidable dependency
  check, and renamed public variables to snake_case with legacy compatibility.
- Fixed live Jenkins SSH credential binding for the shared SSH-agent helper.
- Fixed live-test role resolution from Jenkins job-named workspaces.
- Waited for DigitalOcean test-droplet SSH readiness to settle before the
  first remote command.
- Gated Jenkins GitHub and Ansible Galaxy release publication behind separate
  environment flags and the `main` branch.
- Verified Jenkins Galaxy publication against the resolved release version by
  checking the pushed Git tag and running a pinned Galaxy install after import.
- Restored failure-only Jenkins Slack notifications after live-test remediation.
- Moved Jenkins credential IDs, Slack notification controls, and runtime values
  into the top-level pipeline environment block.

### Documentation

- Moved test harness documentation into `docs/testing.md`, documented the
  Workspace CLI install path and Compose environment model, and updated
  repository agent instructions so Ansible and Jenkinsfile linting run through
  Workspace.
- Clarified the test procedure with the Workspace CLI install command.
- Added Mermaid flowcharts for the DigitalOcean live-test cleanup path and the
  Jenkins live-test pipeline.
- Added a README link to the repository changelog so release history is easier
  to find.
- Added an upgrade guide for users moving from `2.4.1` to `3.0.0`.
- Added a generic Ansible Galaxy release runbook covering GitHub release
  preparation, Galaxy publication, import-status checks, and pinned install
  verification.
- Documented the Workspace Ansible Galaxy publication commands and token
  configuration.
- Documented reusable Workspace GitHub release commands used by both local
  operators and Jenkins.
- Kept Jenkins release publication as thin calls to the reusable Workspace
  release commands.
- Documented Jenkins credentials and parameters required for automated GitHub
  release and Ansible Galaxy publication.
- Documented the current Galaxy token page, the stale CLI reference to
  `/me/preferences`, and the Jenkins pattern for using a dedicated Galaxy
  publishing account token.
- Grouped the 3.0.0 release notes by scope.

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
