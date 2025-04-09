pipeline {
    agent any

    environment {
        CONSUL_HTTP_ADDR = 'https://consul-ui-dev.pntrzz.com/v1/kv' // Replace with your Consul endpoint

    }

    stages {
        stage('Checkout & Read DEX Configuration') {
            steps {
                script {
                    checkout scm

                    def dexConfig
                    try {
                        dexConfig = readJSON file: 'dex-config.json'
                        if (!dexConfig) {
                            error "dex-config.json is empty or invalid."
                        }
                    } catch (Exception e) {
                        error "Error reading dex-config.json: ${e.getMessage()}"
                    }

                    env.DEX_BU = dexConfig?.BU
                    env.DEX_TEAM = dexConfig?.Team
                    env.DEX_APP = dexConfig?.Application
                    env.DEX_ENV = dexConfig?.env

                    if (!env.DEX_BU || !env.DEX_TEAM || !env.DEX_APP || !env.DEX_ENV) {
                        error "Missing top-level DEX identifiers (BU, Team, Application, env) in dex-config.json"
                    }

                    env.CONSUL_BASE_PREFIX = "${env.DEX_ENV}_${env.DEX_BU}/${env.DEX_TEAM}/${env.DEX_APP}"
                    echo "Consul Base Prefix: 👉👉👉 ✅ ${env.CONSUL_BASE_PREFIX}"
                }
            }
        }

        stage('Install Consul Agent') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'CONSUL_HTTP_TOKEN', variable: 'CONSUL_HTTP_TOKEN')]) {
                        // Install Consul Agent
                        def consulZip = 'consul.zip'
                        def consulUrl = 'https://releases.hashicorp.com/consul/1.10.0/consul_1.10.0_linux_amd64.zip'

                        sh "curl -sSL ${consulUrl} -o ${consulZip}"
                        unzip zipFile: consulZip

                        sh '''
                            chmod +x consul && rm -rf consul.zip
                            export PATH=$PWD:$PATH
                            consul --version
                        '''

                        // Install jq 
                        sh '''
                            echo "jq is not installed. Installing..."
                            ls -la
                            wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -P /tmp
                            mv /tmp/jq-linux-amd64 jq && chmod +x jq
                        '''
                        
                        // Pretty-print Consul JSON output using jq
                        sh '''
                            curl -v $CONSUL_HTTP_ADDR/\\?recurse=true\\&token=${CONSUL_HTTP_TOKEN} | jq -r ".[] | [.Key,(.Value|@base64d)] | @csv"
                        '''
                    }
                }
            }
        }

    }
}