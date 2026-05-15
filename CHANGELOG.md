# CHANGELOG

## [3.0.0 - Unreleased] - 2026-05-13

### Changed

- Refreshed Galaxy-facing metadata, support claims, maintainer details,
  documentation, and role defaults for current Ansible Galaxy and JumpCloud
  Linux agent expectations.
- Modernized the install path for current Debian, Ubuntu, and RedHat-family
  targets, including cleaner dependency lists, DNF `curl-minimal`
  compatibility, bounded Kickstart execution, non-interactive Debian-family
  installs, and recovery when the installed `jcagent` service must be started
  before `jcagent.conf` is created.
- Added opt-in installation on newer unsupported releases in otherwise
  supported distribution families by temporarily presenting the latest supported
  `/etc/os-release` identity during the JumpCloud kickstart run, then restoring
  the original file before registration checks.
- Reworked the role task layout so `tasks/main.yml` is an orchestration entry
  point, registered-system reconciliation is separated from installation, and
  group synchronization plus verification live in focused task files.
- Replaced the legacy Docker, Vagrant, and Travis-era test workflow with a
  scoped `community.docker` validation path and a `digitalocean.cloud`
  integration path that provisions real droplets, applies the role, verifies
  JumpCloud state, and cleans up test resources.
- Added Debian 13 container validation for the temporary install identity path
  and a Debian 13 DigitalOcean live target for unsupported-release validation.
- Advertised Debian 13 as a validated role target in Galaxy metadata and
  documented the required unsupported-release install opt-in for that system.
- Documented the isolated unsupported-release identity test as a maintainer
  check, distinct from the Debian 13 DigitalOcean end-to-end role test.
- Added a Jenkins pipeline, matching the DigitalOcean reserved IP role style,
  for dependency installation, syntax checks, live DigitalOcean JumpCloud tests,
  cleanup, and failure-only Slack notifications.
- Renamed test inventories and normalized DigitalOcean droplet names so Docker
  and DigitalOcean targets are explicit and the `ansible-jumpcloud` prefix is
  applied only once.
- Grouped repeated test-harness conditions into clearer blocks, removed an
  avoidable command-module dependency check from container validation, and
  renamed public variables to snake case while preserving legacy camelCase
  compatibility.

### Fixed

- Fixed JumpCloud registration delegation and added role-level system-group
  membership verification immediately after group synchronization.
- Kept registration checks bounded while allowing a persistent missing system
  record to be reported as unregistered instead of failing before reconciliation.
- Removed obsolete Ubuntu 12 and CentOS 6/7 behavior and terminology in favor
  of the current supported platform matrix and RedHat-family naming.
- Hardened secret handling so JumpCloud API keys, connect keys, API response
  bodies, and request headers stay out of task output and failed-test logs.
- Cleaned up YAML and Ansible task structure for linting, readability, and
  publication readiness.

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
