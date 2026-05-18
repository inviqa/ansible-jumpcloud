# AGENTS.md

## Scope

This file applies to the repository root.

These instructions are mandatory for AI agents editing files in this repository.

## Linting Policy (Always Required)

Whenever an agent creates, edits, renames, or deletes a file, it must run the
relevant linter for that file type before finishing.

If multiple file types are changed, run all corresponding linters.

## File Type to Required Linter

### Shell scripts

Applies to:

- `*.sh`
- shell scripts with shebangs (`#!/bin/bash`, `#!/usr/bin/env bash`, etc.)

Required:

- `shellcheck --enable=all <file>`

### YAML files

Applies to:

- `*.yml`
- `*.yaml`

Required:

- `yamllint <file>`

### Ansible YAML files

Applies to:

- `defaults/**/*.yml`
- `defaults/**/*.yaml`
- `meta/**/*.yml`
- `meta/**/*.yaml`
- `handlers/**/*.yml`
- `handlers/**/*.yaml`
- `tasks/**/*.yml`
- `tasks/**/*.yaml`
- `tests/**/*.yml`
- `tests/**/*.yaml`
- any Ansible playbooks, task files, vars files, or metadata in this role repo

Required:

- `ws ansible-lint`
- `yamllint <file>`

Agents must run `ws ansible-lint` every time an Ansible file is created or
modified, including files under `tests/`, even if other repo-wide lint commands
already pass. Do not run `ansible-lint` directly from the host machine for this
repository.

### Markdown files

Applies to:

- `*.md`

Required:

- `markdownlint -c ~/.markdownlint.json <file>`

### Python files

Applies to:

- `*.py`

Required:

- `ruff check <file>`

### Jenkins pipeline

Applies to:

- `Jenkinsfile`

Required:

- `ws lint-jenkinsfile`

Agents must run `ws lint-jenkinsfile` every time `Jenkinsfile` is created or
modified.

## Execution Rules

1. Lint after each meaningful change set and before final handoff.
2. Do not skip linting because a change is small.
3. Every newly created or modified Ansible file must be validated with
   `ws ansible-lint` before finishing the task.
4. If a linter is unavailable, report it clearly and provide the exact install
   command.
5. Prefer targeted linting for changed files, then run broader linting if
   needed.
6. Fix lint errors introduced by the change.
7. Lint issues must be resolved in code or content; do not silence, suppress,
   or bypass rules unless an explicit, documented exception is approved.
8. For shell scripts, always run `shellcheck --enable=all` and treat reported
   findings, including info-level checks, as actionable.
9. Do not embed Python scripts or snippets inside Bash scripts or Bash command
   strings. If the task is assigned to Bash, implement it in Bash.
10. Shell automation must remain compatible with both macOS and Linux Bash.
    Avoid GNU-only flags or syntax and avoid adding dependencies on non-native
    shell tools unless the dependency is already an explicit, documented
    project requirement.
11. Do not commit user-specific absolute filesystem paths. Use
    repository-relative paths, and use `~` only when a home-relative path is
    genuinely required.
12. Keep JumpCloud API keys, connect keys, system keys, and returned device data
    out of logs. Use `no_log: true` for tasks that transmit or receive those
    values.
13. When adding Workspace commands that pass user input into containers, dispatch
    a fixed command with tokenized arguments. Do not pass user-controlled
    strings through `bash -lc`, `eval`, or command substitution.

## Changelog Policy (Always Required)

1. Whenever code or behavior is changed, update `CHANGELOG.md` in the same
   task.
2. Whenever documentation is added or updated, mention it in `CHANGELOG.md` in
   the same task.
3. Add new work under an `Unreleased` section unless a release is being
   finalized.
4. Do not assign or change a release date for an unreleased section unless
   requested by the user or the change is part of release finalization.
5. Only create or date a release entry when the release is actually being
   finalized.
6. Group entries under clear headings and keep wording concise.

## README Update Policy (Always Required)

1. Whenever repository documentation is added, renamed, moved, or deleted,
   update the root `README.md` in the same task.
2. Keep the `README.md` table of contents aligned with the current document
   structure and available repository guidance.
3. Keep the `README.md` maintainer, support, publication, and installation
   details aligned with the current repository state.

## Suggested Commands

- Shell: `shellcheck --enable=all path/to/file.sh`
- YAML: `yamllint path/to/file.yml`
- Ansible: `ws ansible-lint`
- Jenkinsfile: `ws lint-jenkinsfile`
- Markdown: `markdownlint -c ~/.markdownlint.json AGENTS.md README.md CHANGELOG.md TODO.md`
- Python: `ruff check path/to/file.py`

## Notes

- This policy is strict by default.
- This role installs and configures the JumpCloud Linux agent, so changes must
  stay aligned with current JumpCloud Linux agent compatibility documentation.
- Any exception must be explicitly documented in the task output with reason.
