# CHANGELOG

## [3.1.0] - 2026-05-20 - Jenkins Credential and Documentation Updates

### CI and Workspace

- Namespaced role helpers under `ws ansible ...`, `ws ansible galaxy ...`, and
  grouped Workspace help commands, then updated Jenkins and release docs to use
  the new command surface.
- Kept Ansible, Galaxy, GitHub, and provider CLIs inside the Workspace
  `console` container, including offline `ansible-lint` and isolated container
  Ansible cache paths.
- Hardened non-interactive `ws console <command>` so simple pass-through commands
  are tokenized while quoted shell snippets are rejected with clear guidance.
- Standardized shared credential names for Jenkins and Workspace:
  `GITHUB_TOKEN`, `DIGITAL_OCEAN_API_TOKEN`, `DIGITAL_OCEAN_SSH_KEYS`, and the
  shared `ansible-roles-galaxy-token`, while keeping `DO_OAUTH_TOKEN` as a local
  DigitalOcean API fallback.
- Kept Jenkins operator choices as build parameters for live-test target,
  release version, and GitHub/Galaxy publication gates, with failure-only Slack
  notifications controlled by `SLACK_NOTIFICATIONS_ENABLED == 'true'`.

### Live Tests

- Added optional Workspace-driven DigitalOcean project assignment for live-test
  Droplets, kept tracked examples inert by default, and set Jenkins to assign
  live-test Droplets to `Inviqa Sandbox`.
- Treated `test.digitalocean.ssh_keys` as a Workspace list, serialized it only
  at the container boundary, and validated the selected DigitalOcean SSH key
  against forwarded SSH-agent MD5 fingerprints.
- Replaced free-form live-test limits with explicit phases and targets:
  `ws test-live provision <target>`, `ws test-live cleanup <target>`, and
  `ws test-live full-cycle <target>`.
- Consolidated DigitalOcean live tests on `tests/inventory`, removed redundant
  per-family live inventories, and kept Jenkins on the safe `full-cycle` path
  with a second idempotent cleanup safety net.

### Documentation and Release Readiness

- Updated README, testing, Jenkins CI, and Galaxy release documentation for the
  current credential IDs, Workspace override attributes, release commands, and
  pinned `3.1.0` install target.
- Split oversized Mermaid flowcharts into shorter phase-oriented diagrams for
  Markdown preview readability.
- Documented plain `YYYY-MM-DD` release-heading dates and clarified that pre-PR
  release-prep changelog edits should stay compact in the latest concrete
  release section when no `Unreleased` section exists.
- Simplified Workspace Dockerfile requirement-copy paths and reduced the
  Workspace destroy timeout so local test containers stop faster.
- Kept non-secret credential assertion guidance visible while preserving
  `no_log` on tasks that transmit or receive secret values.

## [3.0.2] - 2026-05-20 - Galaxy Check Output

- Clarified the Galaxy release check output so it reports missing GitHub
  release state instead of prescribing a publish command.
- Expanded the Galaxy release check output with the resolved release version,
  GitHub release state, and Galaxy pinned-install state.
- Updated the documented Galaxy install target to `3.0.2`.

## [3.0.1] - 2026-05-20 - Jenkins Publication Trigger

- Retargeted the published release version after the local Galaxy publication
  validation consumed `3.0.0`.
- Updated the documented Galaxy install target to `3.0.1`.

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

### Platform Support

- Refreshed Galaxy metadata, support claims, role defaults, and documentation
  for current Ansible Galaxy and JumpCloud Linux agent expectations.
- Added Fedora 43 and RHEL 10 to the validated support matrix.
- Added opt-in installation for newer unsupported releases in otherwise
  supported distribution families, including Debian 13 through a temporary
  `/etc/os-release` identity override.

### Install and Registration

- Modernized Debian, Ubuntu, and RedHat-family install paths, including
  dependency cleanup, bounded Kickstart execution, non-interactive
  Debian-family installs, and minimal-package compatibility for DNF targets.
- Fixed JumpCloud registration delegation, bounded registration checks, and
  persistent missing-system reporting.
- Reworked task structure so installation, registered-system reconciliation,
  system-group synchronization, and verification live in focused task files.
- Added role-level system-group membership verification after synchronization.

### Security and Secret Handling

- Hardened secret handling so JumpCloud API keys, connect keys, API response
  bodies, and request headers stay out of task output and failed-test logs.
- Added sanitized duplicate-system diagnostics and serialized cleanup retries
  without leaking JumpCloud data.
- Hardened Workspace console command dispatch so pass-through commands execute
  as tokenized container arguments instead of shell-evaluated strings.

### Test Harness and CI

- Replaced the legacy Docker, Vagrant, and Travis-era workflow with a
  Workspace-managed container and DigitalOcean integration harness.
- Standardized validation through Workspace commands, including `ws enable`,
  `ws console`, `ws ansible lint`, `ws ansible syntax`, `ws test-docker`,
  `ws test-live`, and `ws ansible playbook <playbook> <inventory>`.
- Fixed Jenkins live-test reliability around Docker socket access, SSH agent
  credential binding, job-named workspaces, DigitalOcean SSH readiness, and
  JumpCloud SSH-attribute propagation.
- Added Workspace GitHub release and Ansible Galaxy publication commands, then
  wired optional `main`-branch Jenkins publication stages around them.
- Centralized Jenkins credential binding in the top-level pipeline environment
  and credential forwarding at the `ws console` boundary with
  `docker compose exec -e`.
- Defaulted Jenkins `main` builds to publish the GitHub release and import the
  role into Galaxy after validation, while keeping both steps separately
  disableable with build parameters.
- Added release preflight checks for pending GitHub releases, Galaxy token
  configuration, and Galaxy role read access while avoiding the Galaxy
  import-status endpoint because it can return server errors.

### Documentation

- Added an upgrade guide for users moving from `2.4.1` to `3.0.0`.
- Moved test harness guidance into `docs/testing.md` and documented the
  Workspace CLI install path, validation commands, and live-test cleanup flow.
- Documented reusable Workspace GitHub release and Ansible Galaxy publication
  commands for both local operators and Jenkins.
- Updated Jenkins CI documentation with credential requirements, release
  controls, top-level credential binding, and centralized Workspace console
  credential forwarding.
- Added README and agent guidance for the changelog, Workspace-first linting,
  Jenkins validation, and release-publication boundaries.

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
