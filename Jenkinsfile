@Library('pipeline-utils@main') _

pipeline {
    agent any

    environment {
        CONSUL_HTTP_ADDR = 'http://34.238.184.38:8500/v1/kv'
    }

    stages {
        stage('Initialize') {
            steps {
                checkout scm
                parseBranchConfig(env.GIT_BRANCH)
            }
        }

        stage('Deploy Config') {
            steps {
                script {
                    consulConfigManager(
                        consulVersion: '1.10.0',
                        consulAddr: env.CONSUL_HTTP_ADDR
                    )
                }
            }
        }
    }
}
