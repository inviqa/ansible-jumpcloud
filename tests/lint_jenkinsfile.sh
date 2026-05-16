#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' "Usage: $0 [path/to/Jenkinsfile]"
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 127
    fi
}

log_step() {
    printf '\n==> %s\n' "$1"
}

cleanup() {
    status=$?

    if [[ -n "${container_name:-}" ]]; then
        log_step "Deleting Docker container: ${container_name}"
        docker stop "${container_name}" >/dev/null 2>&1 || true
    fi

    if [[ -n "${jenkins_home:-}" ]]; then
        log_step "Removing temporary Jenkins home: ${jenkins_home}"
        rm -rf "${jenkins_home}"
    fi

    exit "${status}"
}

if [[ "${1:-}" = "-h" ]] || [[ "${1:-}" = "--help" ]]; then
    usage
    exit 0
fi

require_command curl
require_command docker

log_step "Resolving Jenkinsfile path"

script_dir=$(CDPATH='' cd -- "$(dirname -- "${0}")" && pwd)
repo_root=$(CDPATH='' cd -- "${script_dir}/.." && pwd)
jenkinsfile_arg=${1:-Jenkinsfile}

if [[ "${jenkinsfile_arg#/}" != "${jenkinsfile_arg}" ]]; then
    jenkinsfile_path=${jenkinsfile_arg}
elif [[ -f "${PWD}/${jenkinsfile_arg}" ]]; then
    jenkinsfile_path=${PWD}/${jenkinsfile_arg}
else
    jenkinsfile_path=${repo_root}/${jenkinsfile_arg}
fi

if [[ ! -f "${jenkinsfile_path}" ]]; then
    printf 'Jenkinsfile not found: %s\n' "${jenkinsfile_arg}" >&2
    exit 1
fi

jenkins_image=${JENKINS_LINT_IMAGE:-jenkins/jenkins:lts-jdk17}
container_name="ansible-jumpcloud-jenkins-lint-$$"
jenkins_home=$(mktemp -d "${TMPDIR:-/tmp}/jenkins-lint.XXXXXX")
plugin_dir="${jenkins_home}/plugins"
init_dir="${jenkins_home}/init.groovy.d"
cookie_file="${jenkins_home}/cookies.txt"

trap cleanup EXIT INT TERM

log_step "Preparing temporary Jenkins home: ${jenkins_home}"
mkdir -p "${plugin_dir}" "${init_dir}"
chmod 0777 "${jenkins_home}" "${plugin_dir}" "${init_dir}"

cat > "${init_dir}/disable-security.groovy" <<'GROOVY'
#!groovy
import jenkins.model.Jenkins

Jenkins.instance.setSecurityRealm(null)
Jenkins.instance.setAuthorizationStrategy(null)
Jenkins.instance.save()
GROOVY

plugins=(
    workflow-aggregator
    pipeline-model-definition
    docker-workflow
    credentials-binding
    ssh-agent
    slack
    timestamper
    ws-cleanup
)

log_step "Installing Jenkins lint plugins"
docker run --rm \
    -v "${plugin_dir}:/usr/share/jenkins/ref/plugins" \
    "${jenkins_image}" \
    jenkins-plugin-cli --plugins "${plugins[@]}"

log_step "Starting Docker container: ${container_name}"
docker run -d --rm \
    --name "${container_name}" \
    -p 127.0.0.1::8080 \
    -v "${jenkins_home}:/var/jenkins_home" \
    -e JAVA_OPTS='-Djenkins.install.runSetupWizard=false' \
    "${jenkins_image}" >/dev/null

published_port=$(docker port "${container_name}" 8080/tcp | awk -F: 'NR == 1 { print $NF }')
jenkins_url="http://127.0.0.1:${published_port}"

log_step "Waiting for Jenkins at ${jenkins_url}"
for _ in $(seq 1 90); do
    if curl -fsS "${jenkins_url}/login" >/dev/null 2>&1 ||
        curl -fsS "${jenkins_url}/" >/dev/null 2>&1; then
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

log_step "Validating ${jenkinsfile_path}"
validation_output=$(curl -fsS -X POST \
    -b "${cookie_file}" \
    -H "${crumb}" \
    -F "jenkinsfile=<${jenkinsfile_path}" \
    "${jenkins_url}/pipeline-model-converter/validate")

printf '%s\n' "${validation_output}"

case ${validation_output} in
    *"Jenkinsfile successfully validated."*)
        log_step "Jenkinsfile validation passed"
        ;;
    *)
        log_step "Jenkinsfile validation failed"
        exit 1
        ;;
esac
