def failureMessages = []

def runWithSshAgent(String command, String credentialId) {
    sshagent(credentials: [credentialId]) {
        sh command
    }
}

pipeline {
    agent {
        docker {
            label 'linux-amd64'
            alwaysPull true
            image 'quay.io/inviqa_images/ansible:2.15-python3.10-trixie'
            args '--entrypoint=""'
        }
    }

    environment {
        ANSIBLE_COLLECTIONS_PATH = ".ansible/collections:/home/ansible/.ansible/collections:/usr/share/ansible/collections"
        ANSIBLE_FORCE_COLOR = 'true'
        ANSIBLE_GALAXY_TOKEN_CREDENTIAL_ID = 'ansible-jumpcloud-galaxy-token'
        ANSIBLE_ROLES_PATH = "tests/roles:.ansible/roles:/home/ansible/.ansible/roles"
        DO_SSH_KEYS_CREDENTIAL_ID = 'ansible-jumpcloud-digitalocean-ssh-key-ids'
        DO_TOKEN_CREDENTIAL_ID = 'ansible-jumpcloud-digitalocean-oauth-token'
        GITHUB_RELEASE_CREDENTIAL_ID = 'inviqa-ansible-roles-releases'
        JUMPCLOUD_API_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-api-key'
        JUMPCLOUD_CONNECT_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-connect-key'
        PIP_BREAK_SYSTEM_PACKAGES = '1'
        PUBLISH_ANSIBLE_GALAXY_RELEASE = 'false'
        PUBLISH_GITHUB_RELEASE = 'false'
        SLACK_NOTIFICATION_CHANNEL = 'ops-integrations'
        SLACK_NOTIFICATIONS_ENABLED = 'true'
        SLACK_TOKEN_CREDENTIAL_ID = 'inviqa-slack-integration-token'
        SSH_PRIVATE_KEY_CREDENTIAL_ID = 'ansible-roles-test-ssh-private-key'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    parameters {
        booleanParam(
            name: 'RUN_LIVE_TESTS',
            defaultValue: true,
            description: 'Run the DigitalOcean-backed JumpCloud live integration test matrix.'
        )
        string(
            name: 'RELEASE_VERSION',
            defaultValue: '',
            description: 'Optional release version to publish. Leave blank to use the latest concrete CHANGELOG.md release section.'
        )
        choice(
            name: 'TEST_INVENTORY',
            choices: ['tests/inventory-digitalocean-droplets'],
            description: 'Inventory used for the live test and cleanup playbooks.'
        )
    }

    stages {
        stage('Install Ansible dependencies') {
            steps {
                sh 'python3 -m pip install --user -r tests/requirements.txt'
                sh 'ansible-galaxy collection install -r tests/requirements.yml -p .ansible/collections'
            }
            post {
                failure {
                    script { failureMessages << 'Ansible dependency installation failed' }
                }
            }
        }

        stage('Syntax checks') {
            steps {
                sh 'ansible-playbook --syntax-check -i tests/inventory-docker tests/playbook.yml'
                sh 'ansible-playbook --syntax-check -i tests/inventory-digitalocean-droplets tests/playbook.yml'
                sh 'ansible-playbook --syntax-check -i tests/inventory-digitalocean-droplets tests/playbook_cleanup.yml'
            }
            post {
                failure {
                    script { failureMessages << 'Ansible playbook syntax checks failed' }
                }
            }
        }

        stage('Live DigitalOcean JumpCloud tests') {
            when {
                expression { return params.RUN_LIVE_TESTS }
            }
            steps {
                script {
                    if (!['tests/inventory-digitalocean-droplets'].contains(params.TEST_INVENTORY)) {
                        error 'Unsupported TEST_INVENTORY parameter.'
                    }

                    withCredentials([
                        string(credentialsId: env.DO_TOKEN_CREDENTIAL_ID, variable: 'DIGITAL_OCEAN_API_TOKEN'),
                        string(credentialsId: env.DO_SSH_KEYS_CREDENTIAL_ID, variable: 'DO_SSH_KEYS'),
                        string(credentialsId: env.JUMPCLOUD_CONNECT_KEY_CREDENTIAL_ID, variable: 'JUMPCLOUD_X_CONNECT_KEY'),
                        string(credentialsId: env.JUMPCLOUD_API_KEY_CREDENTIAL_ID, variable: 'JUMPCLOUD_API_KEY')
                    ]) {
                        sh '''
                            set -eu
                            umask 077
                            {
                                printf '%s\n' '---'
                                printf '%s\n' 'do_ssh_keys:'
                                printf '%s\n' "$DO_SSH_KEYS" |
                                    tr ',' '\\n' |
                                    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
                                    awk 'NF { printf "  - \\"%s\\"\\n", $0 }'
                            } > tests/test_variables.yml
                        '''

                        try {
                            runWithSshAgent(
                                "ansible-playbook -i '${params.TEST_INVENTORY}' tests/playbook.yml",
                                env.SSH_PRIVATE_KEY_CREDENTIAL_ID
                            )
                        } finally {
                            runWithSshAgent(
                                "ansible-playbook -i '${params.TEST_INVENTORY}' tests/playbook_cleanup.yml",
                                env.SSH_PRIVATE_KEY_CREDENTIAL_ID
                            )
                        }
                    }
                }
            }
            post {
                failure {
                    script { failureMessages << 'Live DigitalOcean JumpCloud integration tests failed' }
                }
            }
        }

        stage('Publish GitHub release') {
            when {
                allOf {
                    branch 'main'
                    expression { return env.PUBLISH_GITHUB_RELEASE.toBoolean() }
                }
            }
            steps {
                withCredentials([string(
                    credentialsId: env.GITHUB_RELEASE_CREDENTIAL_ID,
                    variable: 'GITHUB_TOKEN'
                )]) {
                    sh 'RELEASE_VERSION="${RELEASE_VERSION}" ws github release publish'
                }
            }
            post {
                failure {
                    script { failureMessages << 'GitHub release publication failed' }
                }
            }
        }

        stage('Publish Ansible Galaxy release') {
            when {
                allOf {
                    branch 'main'
                    expression { return env.PUBLISH_ANSIBLE_GALAXY_RELEASE.toBoolean() }
                }
            }
            steps {
                withCredentials([string(
                    credentialsId: env.ANSIBLE_GALAXY_TOKEN_CREDENTIAL_ID,
                    variable: 'ANSIBLE_GALAXY_TOKEN'
                )]) {
                    sh 'RELEASE_VERSION="${RELEASE_VERSION}" ws ansible-galaxy publish'
                }
            }
            post {
                failure {
                    script { failureMessages << 'Ansible Galaxy release publication failed' }
                }
            }
        }
    }

    post {
        failure {
            script {
                def message = "ansible-jumpcloud: ${env.JOB_BASE_NAME} #${env.BUILD_NUMBER} - Failure after ${currentBuild.durationString.minus(' and counting')} (<${env.RUN_DISPLAY_URL}|View Build>)"
                def fallbackMessages = [ message ]
                def fields = []

                def failureMessage = failureMessages.join("\n")
                if (failureMessage) {
                    fields << [
                        title: 'Reason(s)',
                        value: failureMessage,
                        short: false
                    ]
                    fallbackMessages << failureMessage
                }
                def attachments = [
                    [
                        text: message,
                        fallback: fallbackMessages.join("\n"),
                        color: 'danger',
                        fields: fields
                    ]
                ]
                if (!env.SLACK_NOTIFICATIONS_ENABLED.toBoolean()) {
                    echo "Slack ${currentBuild.currentResult} notification skipped; SLACK_NOTIFICATIONS_ENABLED is false."
                } else {
                    slackSend(channel: env.SLACK_NOTIFICATION_CHANNEL, color: 'danger', attachments: attachments, tokenCredentialId: env.SLACK_TOKEN_CREDENTIAL_ID)
                }
            }
        }
        always {
            sh 'rm -f tests/test_variables.yml'
            cleanWs()
        }
    }
}
