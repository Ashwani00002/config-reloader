@Library('jenkins-shared-libs') _

pipeline {
    agent any

    environment {
        CONSUL_HTTP_ADDR = 'http://34.238.184.38:8500/v1/kv' 
    }

    stages {
        stage('Checkout & Parse Branch Name') {
            steps {
                script {
                    def branchInfo = parseBranchName(env.GIT_BRANCH)
                    env.ENV = branchInfo.env
                    env.CLUSTER = branchInfo.cluster
                    env.APPLICATION_CONFIG_MAP = branchInfo.applicationConfigMap
                    echo "ENV: ${env.ENV}, CLUSTER: ${env.CLUSTER}, APPLICATION_CONFIG_MAP: ${env.APPLICATION_CONFIG_MAP}"
                }
                checkout scm
            }
        }

        stage('Deploy Config to Consul') {
            steps {
                script {
                    deployConfigToConsul(
                        env: env.ENV,
                        cluster: env.CLUSTER,
                        applicationConfigMap: env.APPLICATION_CONFIG_MAP,
                        consulHttpAddr: env.CONSUL_HTTP_ADDR
                    )
                }
            }
        }
    }
}