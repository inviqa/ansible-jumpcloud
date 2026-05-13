def failureMessages = []
def DO_TOKEN_CREDENTIAL_ID = 'ansible-jumpcloud-digitalocean-oauth-token'
def DO_SSH_KEYS_CREDENTIAL_ID = 'ansible-jumpcloud-digitalocean-ssh-key-ids'
def JUMPCLOUD_CONNECT_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-connect-key'
def JUMPCLOUD_API_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-api-key'
def SSH_PRIVATE_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-test-ssh-private-key'
def SLACK_TOKEN_CREDENTIAL_ID = 'inviqa-slack-integration-token'

def runWithSshAgent(String command) {
    sshagent(credentials: [SSH_PRIVATE_KEY_CREDENTIAL_ID]) {
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

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        ANSIBLE_COLLECTIONS_PATH = ".ansible/collections:/home/ansible/.ansible/collections:/usr/share/ansible/collections"
        ANSIBLE_FORCE_COLOR = 'true'
        ANSIBLE_ROLES_PATH = "tests/roles:.ansible/roles:/home/ansible/.ansible/roles"
        PIP_BREAK_SYSTEM_PACKAGES = '1'
        SLACK_NOTIFICATION_CHANNEL = 'ops-integrations'
    }

    parameters {
        booleanParam(
            name: 'RUN_LIVE_TESTS',
            defaultValue: true,
            description: 'Run the DigitalOcean-backed JumpCloud live integration test matrix.'
        )
        string(
            name: 'TEST_INVENTORY',
            defaultValue: 'tests/inventory-digitalocean-droplets',
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
                    withCredentials([
                        string(credentialsId: DO_TOKEN_CREDENTIAL_ID, variable: 'DIGITAL_OCEAN_API_TOKEN'),
                        string(credentialsId: DO_SSH_KEYS_CREDENTIAL_ID, variable: 'DO_SSH_KEYS'),
                        string(credentialsId: JUMPCLOUD_CONNECT_KEY_CREDENTIAL_ID, variable: 'JUMPCLOUD_X_CONNECT_KEY'),
                        string(credentialsId: JUMPCLOUD_API_KEY_CREDENTIAL_ID, variable: 'JUMPCLOUD_API_KEY')
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
                            runWithSshAgent("ansible-playbook -i '${params.TEST_INVENTORY}' tests/playbook.yml")
                        } finally {
                            runWithSshAgent("ansible-playbook -i '${params.TEST_INVENTORY}' tests/playbook_cleanup.yml")
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

                slackSend(channel: env.SLACK_NOTIFICATION_CHANNEL, color: 'danger', attachments: attachments, tokenCredentialId: SLACK_TOKEN_CREDENTIAL_ID)
            }
        }
        always {
            sh 'rm -f tests/test_variables.yml'
            cleanWs()
        }
    }
}
