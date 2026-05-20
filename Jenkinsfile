def failureMessages = []

pipeline {
    agent { label 'linux-amd64' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        ANSIBLE_GALAXY_TOKEN = credentials('ansible-jumpcloud-galaxy-token')
        DIGITAL_OCEAN_SSH_KEYS = credentials('ansible-roles-tests-digitalocean-ssh-key-id')
        DIGITAL_OCEAN_API_TOKEN = credentials('ansible-roles-digitalocean-oauth-token')
        GITHUB_TOKEN = credentials('inviqa-ansible-roles-releases')
        JUMPCLOUD_API_KEY = credentials('ansible-jumpcloud-api-key')
        JUMPCLOUD_X_CONNECT_KEY = credentials('ansible-jumpcloud-connect-key')
        LIVE_TEST_TARGET = 'all'
        PUBLISH_ANSIBLE_GALAXY_RELEASE = 'true'
        PUBLISH_GITHUB_RELEASE = 'true'
        RELEASE_VERSION = ''
        RUN_LIVE_TESTS = 'true'
        SLACK_NOTIFICATION_CHANNEL = 'ops-integrations'
        SLACK_NOTIFICATIONS_ENABLED = 'true'
        SLACK_TOKEN_CREDENTIAL_ID = 'inviqa-slack-integration-token'
        SSH_PRIVATE_KEY_CREDENTIAL_ID = 'ansible-roles-test-ssh-private-key'
    }

    stages {
        stage('Build') {
            steps {
                sh 'ws enable'
                milestone(10)
            }
            post {
                failure {
                    script { failureMessages << 'Workspace environment failed to enable' }
                }
            }
        }

        stage('Linting') {
            steps {
                sh 'ws ansible-lint'
            }
            post {
                failure {
                    script { failureMessages << 'Ansible linting failed' }
                }
            }
        }

        stage('Syntax checks') {
            steps {
                sh 'ws syntax'
            }
            post {
                failure {
                    script { failureMessages << 'Ansible playbook syntax checks failed' }
                }
            }
        }

        stage('Container tests') {
            steps {
                sh 'ws test-docker'
            }
            post {
                failure {
                    script { failureMessages << 'Container-backed JumpCloud role tests failed' }
                }
            }
        }

        stage('Release preflight') {
            steps {
                sh '''
                    set +e
                    ws github release check
                    github_release_status="$?"
                    set -e

                    [ "${github_release_status}" = 0 ] || [ "${github_release_status}" = 2 ] || exit "${github_release_status}"

                    ws ansible-galaxy check-token
                    ws ansible-galaxy info
                '''
            }
            post {
                failure {
                    script { failureMessages << 'Release preflight checks failed' }
                }
            }
        }

        stage('Live DigitalOcean JumpCloud tests') {
            when {
                expression { return env.RUN_LIVE_TESTS == 'true' }
            }
            steps {
                sshagent(credentials: [env.SSH_PRIVATE_KEY_CREDENTIAL_ID]) {
                    sh 'ws test-live "${LIVE_TEST_TARGET}"'
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
                    expression { return env.PUBLISH_GITHUB_RELEASE == 'true' }
                }
            }
            steps {
                sh 'ws github release publish'
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
                    expression { return env.PUBLISH_ANSIBLE_GALAXY_RELEASE == 'true' }
                }
            }
            steps {
                sh 'ws ansible-galaxy publish'
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
            sh 'ws destroy'
            cleanWs()
        }
    }
}
