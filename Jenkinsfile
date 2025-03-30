@Library('jenkins-shared-libs') _

pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                script {
                    def branchInfo = parseBranchName('dev.test.app')
                    println branchInfo
                }
            }
        }
    }
}