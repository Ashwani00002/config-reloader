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

        stage('Synchronize DEX Configuration with Consul') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'CONSUL_HTTP_TOKEN', variable: 'CONSUL_HTTP_TOKEN')]) {
                        def dexConfig = readJSON file: 'dex-config.json'
                        def consulBasePrefix = env.CONSUL_BASE_PREFIX
                        def consulHttpAddr = env.CONSUL_HTTP_ADDR
                        def consulToken = env.CONSUL_HTTP_TOKEN
                        def headers = [
                            'Content-Type: application/json',
                            "X-Consul-Token: ${consulToken}"
                        ]

                        def fetchConsulKeys = { String prefix ->
                            def consulKeys = []
                            def queryUrl = "${consulHttpAddr}/${prefix}?recurse=true&token=${consulToken}"
                            try {
                                def response = sh(script: "curl -s ${queryUrl}", returnStdout: true).trim()
                                def jsonResponse = readJSON text: response
                                jsonResponse?.each { item ->
                                    consulKeys << item.Key
                                }
                            } catch (Exception e) {
                                echo "Error fetching Consul keys for prefix '${prefix}': ${e.getMessage()}"
                            }
                            return consulKeys
                        }

                        def putValueToConsul = { String keyPath, String value, List createdOrModified ->
                            def putUrl = "${consulHttpAddr}/${keyPath}"
                            try {
                                sh """
                                    curl -X PUT -H "${headers.join('" -H "')}" -d '${value}' "${putUrl}"
                                """
                                createdOrModified << keyPath
                            } catch (Exception e) {
                                error "Failed to put key '${keyPath}' with value '${value}' to Consul: ${e.getMessage()}"
                            }
                        }

                        def deleteKeyFromConsul = { String keyPath, List deleted ->
                            def deleteUrl = "${consulHttpAddr}/${keyPath}"
                            try {
                                sh """
                                    curl -X DELETE -H "X-Consul-Token: ${consulToken}" "${deleteUrl}"
                                """
                                echo "Deleted key: ${keyPath} from Consul."
                                deleted << keyPath
                            } catch (Exception e) {
                                error "Failed to delete key '${keyPath}' from Consul: ${e.getMessage()}"
                            }
                        }

                        def processConnector = { connectorType, config, createdOrModified, deleted ->
                            def consulPrefix = "${consulBasePrefix}/${connectorType}"
                            def currentConsulKeys = fetchConsulKeys(consulPrefix)
                            def expectedConsulKeys = []

                            if (config) {
                                def connectorName = config.keySet().first()
                                def connectorData = config[connectorName]
                                if (connectorName && connectorData) {
                                    echo "Processing ${connectorType} (${connectorName})..."
                                    connectorData.each { key, value ->
                                        def consulKey = "${consulPrefix}/${connectorName}/${key}"
                                        putValueToConsul(consulKey, value, createdOrModified)
                                        expectedConsulKeys << consulKey
                                    }
                                }
                            }

                            currentConsulKeys.each { consulKey ->
                                if (!expectedConsulKeys.contains(consulKey) && consulKey.startsWith("${consulPrefix}/")) {
                                    deleteKeyFromConsul(consulKey, deleted)
                                }
                            }
                        }

                        def createdModifiedKeys = []
                        def deletedKeys = []

                        processConnector("SOURCE_CONNECTOR", dexConfig?.SOURCE_CONNECTOR, createdModifiedKeys, deletedKeys)
                        processConnector("TASK_CONNECTOR", dexConfig?.TASK_CONNECTOR, createdModifiedKeys, deletedKeys)
                        processConnector("SINK_CONNECTOR", dexConfig?.SINK_CONNECTOR, createdModifiedKeys, deletedKeys)

                        // Store results in environment variables for the summary stage
                        env.CREATED_KEYS = createdModifiedKeys.join('\n')
                        env.DELETED_KEYS = deletedKeys.join('\n')
                    }
                }
            }
        }

        stage('Configuration Changes Summary') {
            steps {
                script {
                    def changes = [created: [], deleted: []]

                    try {
                        changes.created = env.CREATED_KEYS?.split('\n') ?: []
                        changes.deleted = env.DELETED_KEYS?.split('\n') ?: []
                    } catch (Exception e) {
                        error "Failed to get configuration changes: ${e.getMessage()}"
                    }

                    echo "--------------------------------------------------"
                    echo "      DEX Configuration Changes Summary"
                    echo "--------------------------------------------------"
                    echo "Environment: ${env.DEX_ENV}"
                    echo "BU: ${env.DEX_BU}"
                    echo "Team: ${env.DEX_TEAM}"
                    echo "Application: ${env.DEX_APP}"
                    echo "--------------------------------------------------"

                    def printChanges = { String type, List items ->
                        if (items.size() > 0) {
                            echo "\n${type} Configurations:"
                            items.each { key ->
                                // Extract just the connector name and property for cleaner output
                                def displayKey = key.replaceFirst("${env.CONSUL_BASE_PREFIX}/", "")
                                echo "  ${(type == 'Created/Modified') ? '🟢 +' : '🔴 -'} ${displayKey}"
                            }
                        } else {
                            echo "\nNo configurations were ${type.toLowerCase()}."
                        }
                    }

                    printChanges("Created/Modified", changes.created)
                    printChanges("Deleted", changes.deleted)

                    echo "\n--------------------------------------------------"
                    echo "Total Changes:"
                    echo "Created/Modified: ${changes.created.size()}"
                    echo "Deleted: ${changes.deleted.size()}"
                    echo "--------------------------------------------------"
                }
            }
        }
    }

}