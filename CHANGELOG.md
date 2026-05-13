# CHANGELOG

## Unreleased

### Changed

- Refreshed Galaxy metadata for current publication expectations, including
  namespace, maintainer, supported platform families, and modern Ansible
  minimum version.
- Removed obsolete or conflict-prone dependency packages from the install path
  so modern Debian, Ubuntu, and Rocky Linux images can resolve packages cleanly.
- Switched kickstart execution through `/bin/bash` so container `/tmp` mount
  options do not block the downloaded installer.
- Added a bounded installer timeout so unsupported or unhealthy environments
  fail diagnostically instead of hanging the harness.
- Kept JumpCloud installer execution bounded and sensitive because JumpCloud
  prints the connect key, and made Debian-family kickstart execution
  non-interactive.
- Split container validation from live-host agent registration so Docker tests
  no longer attempt to register unsupported container targets as JumpCloud
  devices.
- Replaced the legacy Docker, Vagrant, and Travis-era test harness dependency
  with a maintained `community.docker` container harness plus live-host
  inventory support.
- Added a DigitalOcean-backed integration harness that provisions real droplets,
  applies the JumpCloud role, verifies local agent state and JumpCloud API
  attributes, then deletes the droplets during cleanup.
- Switched DigitalOcean live-test provisioning to the maintained
  `digitalocean.cloud` collection and documented its Python runtime
  dependencies.
- Normalized DigitalOcean test droplet names so the `ansible-jumpcloud` prefix
  is applied only once.
- Renamed test inventories so Docker and DigitalOcean droplet targets are
  explicit in the filename.
- Refactored the role entrypoint into smaller task files so `tasks/main.yml`
  reads as an orchestration sequence.
- Added a post-package service-start recovery path for Debian-family installs
  where the JumpCloud package is installed but the agent service is not started
  before the kickstart command times out.
- Updated role defaults and dependency lists to track JumpCloud's current Linux
  agent compatibility documentation.
- Renamed public role variables to Ansible-lint-compatible snake case while
  keeping compatibility reads for legacy camelCase variable names.
- Rewrote the README and test documentation for current Galaxy preparation,
  support matrix, secret handling, and live-test workflow.

### Fixed

- Fixed broken delegation in the JumpCloud registration check task.
- Removed legacy Ubuntu 12 install workaround and obsolete CentOS 6/7 support
  claims.
- Stopped exposing JumpCloud API keys and connect keys through debug output.
- Marked JumpCloud group-validation assertions as sensitive so failed live tests
  cannot print API response bodies or request headers.
- Modernized YAML and Ansible task structure for linting and publication
  readiness.
- Renamed the CentOS-specific test inventory to Enterprise Linux/RedHat
  terminology.

## v2.4.0

- Ansible-lint adjustments.
- Ansible requirements pinning for testing environment.
- Removed package installation loops.
- Made the JumpCloud dependencies organization more organic.

## v2.3.0

- Ansible requirements pinning for testing environment.
- Removed package installation loops.
- Made the JumpCloud dependencies organization more organic.

## v2.2.0

- Verified if a system is correctly registered in JumpCloud.
- Automated deletion of previously registered servers with the same name in
  JumpCloud.
- Automated deletion of registered servers in JumpCloud for testing cleanup.
- Removed support for Ubuntu 12.04 testing.

## v2.1.0

- Replaced Vagrant testing with Docker testing.
- Added test tasks and playbook to test on Debian stable, Ubuntu 12.04, Ubuntu
  14.04, Ubuntu 16.04, Ubuntu 18.04, CentOS 6, and CentOS 7.
- Added Travis CI testing.

## v2.0.0

- Implemented API v2 task to handle system groups.
- Removed support for tags after they were converted to groups.
- Added a conditional check to add systems to groups only when system groups are
  defined in `jumpcloud_system_groups`.
