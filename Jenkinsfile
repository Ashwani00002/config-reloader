pipeline {
    agent any

    environment {
        CONSUL_HTTP_ADDR = 'http://54.163.131.39:8500/v1/kv' // Replace with your Consul endpoint
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
                }
            }
        }

        stage('Upload DEX Configuration to Consul') {
            steps {
                script {
                    def dexConfig = readJSON file: 'dex-config.json'

                    def uploadConnectorConfig = { connectorType, config ->
                        if (config) {
                            def connectorName = config.keySet().first() // Get "Kafka", "HTTP", "DynamoDB"
                            def connectorConfigData = config[connectorName] // Get the nested config
                            if (connectorName && connectorConfigData) {
                                echo "Uploading ${connectorType} (${connectorName}) configuration..."
                                connectorConfigData.each { key, value ->
                                    def consulKey = "${env.CONSUL_BASE_PREFIX}/${connectorType}/${connectorName}/${key}"
                                    sh "consul kv put -http-addr=${env.CONSUL_ENDPOINT} ${consulKey} '${value}'"
                                }
                            } else {
                                echo "No valid configuration found for ${connectorType}."
                            }
                        } else {
                            echo "${connectorType} configuration not found in dex-config.json."
                        }
                    }

                    uploadConnectorConfig("SOURCE_CONNECTOR", dexConfig?.SOURCE_CONNECTOR)
                    uploadConnectorConfig("TASK_CONNECTOR", dexConfig?.TASK_CONNECTOR)
                    uploadConnectorConfig("SINK_CONNECTOR", dexConfig?.SINK_CONNECTOR)
                }
            }
        }
    }
}