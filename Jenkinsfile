@Library("jenkins-shared-libs") _

pipeline {
    agent any
    
    stages {
        stage('Initialize Configuration') {
            steps {
                checkout scm
                parseBranchConfig(env.GIT_BRANCH)
            }
        }
        
        stage('Consul Configuration') {
            environment {
                CONSUL_HTTP_ADDR = 'http://34.238.184.38:8500/v1/kv'
            }
            steps {
                consulConfigManager(
                    consulVersion: '1.10.0',
                    consulAddr: env.CONSUL_HTTP_ADDR
                )
            }
        }
    }
}
