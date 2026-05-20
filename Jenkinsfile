def failureMessages = []

pipeline {
    agent { label 'linux-amd64' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        ANSIBLE_GALAXY_TOKEN_CREDENTIAL_ID = 'ansible-jumpcloud-galaxy-token'
        ANSIBLE_GALAXY_TOKEN = credentials('ansible-jumpcloud-galaxy-token')
        DO_SSH_KEYS_CREDENTIAL_ID = 'ansible-jumpcloud-digitalocean-ssh-key-ids'
        DO_SSH_KEYS = credentials('ansible-jumpcloud-digitalocean-ssh-key-ids')
        DO_TOKEN_CREDENTIAL_ID = 'ansible-jumpcloud-digitalocean-oauth-token'
        DIGITAL_OCEAN_API_TOKEN = credentials('ansible-jumpcloud-digitalocean-oauth-token')
        DO_OAUTH_TOKEN = credentials('ansible-jumpcloud-digitalocean-oauth-token')
        GITHUB_RELEASE_CREDENTIAL_ID = 'inviqa-ansible-roles-releases'
        GITHUB_TOKEN = credentials('inviqa-ansible-roles-releases')
        GH_TOKEN = credentials('inviqa-ansible-roles-releases')
        JUMPCLOUD_API_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-api-key'
        JUMPCLOUD_API_KEY = credentials('ansible-jumpcloud-api-key')
        JUMPCLOUD_CONNECT_KEY_CREDENTIAL_ID = 'ansible-jumpcloud-connect-key'
        JUMPCLOUD_X_CONNECT_KEY = credentials('ansible-jumpcloud-connect-key')
        PUBLISH_ANSIBLE_GALAXY_RELEASE = 'false'
        PUBLISH_GITHUB_RELEASE = 'false'
        SLACK_NOTIFICATION_CHANNEL = 'ops-integrations'
        SLACK_NOTIFICATIONS_ENABLED = 'true'
        SLACK_TOKEN_CREDENTIAL_ID = 'inviqa-slack-integration-token'
        SSH_PRIVATE_KEY_CREDENTIAL_ID = 'ansible-roles-test-ssh-private-key'
    }

    parameters {
        booleanParam(
            name: 'RUN_LIVE_TESTS',
            defaultValue: true,
            description: 'Run the DigitalOcean-backed JumpCloud live integration test matrix.'
        )
        string(
            name: 'LIVE_TEST_LIMIT',
            defaultValue: '',
            description: 'Optional Ansible host limit for ws test-live. Leave blank to run the full live matrix.'
        )
        string(
            name: 'RELEASE_VERSION',
            defaultValue: '',
            description: 'Optional release version to publish. Leave blank to use the latest concrete CHANGELOG.md release section.'
        )
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
                    RELEASE_VERSION="${RELEASE_VERSION:-}" ws github release check
                    github_release_status="$?"
                    set -e

                    [ "${github_release_status}" = 0 ] || [ "${github_release_status}" = 2 ] || exit "${github_release_status}"

                    ws ansible-galaxy status
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
                expression { return params.RUN_LIVE_TESTS }
            }
            steps {
                sshagent(credentials: [env.SSH_PRIVATE_KEY_CREDENTIAL_ID]) {
                    sh 'ws test-live "${LIVE_TEST_LIMIT:-}"'
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
                sh 'RELEASE_VERSION="${RELEASE_VERSION:-}" ws github release publish'
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
                sh 'RELEASE_VERSION="${RELEASE_VERSION:-}" ws ansible-galaxy publish'
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
