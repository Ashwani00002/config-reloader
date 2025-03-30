pipeline {
    agent any

    environment {
        CONSUL_HTTP_ADDR = 'http://34.203.245.87:8500/v1/kv'  // Replace with your Consul endpoint
        
    }

    stages {
        stage('Checkout & Parse Branch Name') {
            steps {
                script {
                    def branchName = env.GIT_BRANCH.replace('origin/', '') // Remove 'origin/' if present
                    def parts = branchName.split('\\.')
                    if (parts.size() == 3) {
                        env.ENV = parts[0]
                        env.CLUSTER = parts[1]
                        env.APPLICATION_CONFIG_MAP = parts[2]
                        echo "ENV: ${env.ENV}, CLUSTER: ${env.CLUSTER}, APPLICATION_CONFIG_MAP: ${env.APPLICATION_CONFIG_MAP}"
                    } else {
                        error "Invalid branch name format. Expected: env.cluster.application-config-map"
                    }
                }
                checkout scm
            }
        }
stage('Install Consul Agent & Process Config') {
    steps {
        script {
            // Install Consul Agent
            def consulZip = 'consul.zip'
            def consulUrl = 'https://releases.hashicorp.com/consul/1.10.0/consul_1.10.0_linux_amd64.zip'

            sh "curl -sSL ${consulUrl} -o ${consulZip}"
            unzip zipFile: consulZip

            sh '''
                chmod +x consul && rm -rf consul.zip
                export PATH=$PWD:$PATH
                consul --version
                curl $CONSUL_HTTP_ADDR/\\?recurse=true
            '''

            // Process Config Map JSON & Upload to Consul
            // def jFile = readJSON file: './config-map-env.json'
            // jFile.each { key, value ->
            //     def consulKey = "${env.ENV}/${env.CLUSTER}/${env.APPLICATION_CONFIG_MAP}/${key}"
            //     echo "Consul Key: ${consulKey}, Value: ${value}" 
            //     sh '''
            //     echo "@@@@@@@@@@@@@@@@@@"
            //     echo "*******************************************"
            //     curl -k --request PUT -d "${value}" "${CONSUL_HTTP_ADDR}/${consulKey}"
            //     '''
            // }


                    try {
                        def jFile = readJSON file: './config-map-env.json'

                        println "JSON data: ${jFile}" // Inspect the JSON structure

                        if (jFile instanceof Map) { // Ensure it's a Map
                            jFile.each { key, value ->
                                def consulKey = "${env.ENV}/${env.CLUSTER}/${env.APPLICATION_CONFIG_MAP}/${key}"
                                echo "Consul Key: ${consulKey}, Value: ${value}"
                                sh "curl -k --request PUT -d '${value}' '${CONSUL_HTTP_ADDR}/${consulKey}'"
                                sh "curl $CONSUL_HTTP_ADDR/\\?recurse=true"
                            }
                        } else {
                            error "Parsed JSON is not a Map (dictionary)."
                        }

                    } catch (Exception e) {
                        error "Failed to process config-map-env.json: ${e.message}"
                    }


                }
            }
        }

    }
}
