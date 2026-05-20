#!/usr/bin/env bash
set -euo pipefail

log_step() {
    printf '\n==> %s\n' "$1"
}

jenkinsfile=${1:-Jenkinsfile}
jenkins_url=${JENKINS_LINT_URL:-http://jenkins-lint:8080}

if [[ ! -f "${jenkinsfile}" ]]; then
    printf 'Jenkinsfile not found: %s\n' "${jenkinsfile}" >&2
    exit 1
fi

cookie_file=$(mktemp "${TMPDIR:-/tmp}/jenkins-lint-cookies.XXXXXX")
trap 'rm -f "${cookie_file}"' EXIT

log_step "Waiting for Jenkins at ${jenkins_url}"
for _ in {1..90}; do
    if curl -fsS "${jenkins_url}/" >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

if ! curl -fsS "${jenkins_url}/" >/dev/null 2>&1; then
    printf 'Timed out waiting for Jenkins at %s\n' "${jenkins_url}" >&2
    exit 1
fi

log_step "Requesting Jenkins crumb"
crumb=$(curl -fsS -c "${cookie_file}" \
    "${jenkins_url}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)")

log_step "Validating ${jenkinsfile}"
validation_output=$(curl -fsS -X POST \
    -b "${cookie_file}" \
    -H "${crumb}" \
    -F "jenkinsfile=<${jenkinsfile}" \
    "${jenkins_url}/pipeline-model-converter/validate")

printf '%s\n' "${validation_output}"

case "${validation_output}" in
    *"Jenkinsfile successfully validated."*)
        log_step "Jenkinsfile validation passed"
        ;;
    *)
        log_step "Jenkinsfile validation failed"
        exit 1
        ;;
esac
