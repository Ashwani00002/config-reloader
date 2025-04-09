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

        stage('Synchronize Configuration') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'CONSUL_HTTP_TOKEN', variable: 'CONSUL_HTTP_TOKEN')]) {
                        def dexConfig = readJSON file: 'dex-config.json'
                        def changes = [
                            created: [],
                            modified: [],
                            deleted: []
                        ]
                        def consulBasePrefix = env.CONSUL_BASE_PREFIX
                        def consulHttpAddr = env.CONSUL_HTTP_ADDR
                        def consulToken = env.CONSUL_HTTP_TOKEN

                        // Function to normalize values for accurate comparison
                        def normalizeValue = { value ->
                            if (value == null) return ""
                            if (value instanceof String) {
                                return value.trim().replaceAll("\\s+", " ")
                            }
                            return readJSON(text: writeJSON(json: value)).toString().trim()
                        }

                        // Fetch all Consul keys under the base prefix
                        def allConsulKeys = []
                        def allConsulValues = [:]
                        def allConsulResponse = sh(script: """
                            curl -s -H "X-Consul-Token: ${consulToken}" \
                            "${consulHttpAddr}/${consulBasePrefix}?recurse=true"
                        """, returnStdout: true).trim()

                        if (allConsulResponse && allConsulResponse != "null") {
                            readJSON(text: allConsulResponse).each { item ->
                                def key = item.Key
                                allConsulKeys << key
                                def valueResponse = sh(script: """
                                    curl -s -H "X-Consul-Token: ${consulToken}" \
                                    "${consulHttpAddr}/${key}?raw=true"
                                """, returnStdout: true).trim()
                                allConsulValues[key] = normalizeValue(valueResponse)
                            }
                        }

                        def expectedConsulKeysThisRun = []

                        ['SOURCE_CONNECTOR', 'TASK_CONNECTOR', 'SINK_CONNECTOR'].each { connectorType ->
                            def currentConfig = dexConfig[connectorType] ?: [:]
                            def consulPrefix = "${consulBasePrefix}/${connectorType}"

                            currentConfig.each { connectorName, connectorConfig ->
                                connectorConfig.each { key, value ->
                                    def fullKey = "${consulPrefix}/${connectorName}/${key}"
                                    def normalizedNewValue = normalizeValue(value)

                                    if (allConsulKeys.contains(fullKey)) {
                                        if (normalizedNewValue != allConsulValues[fullKey]) {
                                            changes.modified << fullKey
                                        }
                                    } else {
                                        changes.created << fullKey
                                    }

                                    // Create/update the key in Consul
                                    sh """
                                        curl -X PUT -H "X-Consul-Token: ${consulToken}" \
                                        -d '${normalizedNewValue}' "${consulHttpAddr}/${fullKey}"
                                    """
                                    expectedConsulKeysThisRun << fullKey
                                }
                            }
                        }

                        // Identify and delete stale keys
                        allConsulKeys.each { consulKey ->
                            if (consulKey.startsWith("${consulBasePrefix}/") && !expectedConsulKeysThisRun.contains(consulKey)) {
                                changes.deleted << consulKey
                                sh """
                                    curl -X DELETE -H "X-Consul-Token: ${consulToken}" \
                                    "${consulHttpAddr}/${consulKey}"
                                """
                            }
                        }

                        // Store changes for summary stage
                        env.CHANGES_CREATED = changes.created.join('\n')
                        env.CHANGES_MODIFIED = changes.modified.join('\n')
                        env.CHANGES_DELETED = changes.deleted.join('\n')
                    }
                }
            }
        }

        stage('Configuration Changes Summary') {
            steps {
                script {
                    def changes = [
                        created: env.CHANGES_CREATED?.split('\n')?.findAll { it } ?: [],
                        modified: env.CHANGES_MODIFIED?.split('\n')?.findAll { it } ?: [],
                        deleted: env.CHANGES_DELETED?.split('\n')?.findAll { it } ?: []
                    ]

                    echo """
                    --------------------------------------------------
                          DEX CONFIGURATION CHANGES
                    --------------------------------------------------
                    Environment: ${env.DEX_ENV}
                    BU: ${env.DEX_BU}
                    Team: ${env.DEX_TEAM}
                    Application: ${env.DEX_APP}
                    --------------------------------------------------
                    """

                    def printChanges = { String category, List items ->
                        if (items) {
                            echo "${category.toUpperCase()} CONFIGURATIONS (${items.size()}):"
                            items.each { key ->
                                def displayKey = key.replace("${env.CONSUL_BASE_PREFIX}/", "")
                                echo "  ${category == 'created' ? '🟢' : category == 'modified' ? '🟡' : '🔴'} ${displayKey}"
                            }
                            echo ""
                        } else {
                            echo "NO ${category.toUpperCase()} CONFIGURATIONS\n"
                        }
                    }

                    printChanges('created', changes.created)
                    printChanges('modified', changes.modified)
                    printChanges('deleted', changes.deleted)

                    echo """
                    --------------------------------------------------
                    SUMMARY:
                      Created: ${changes.created.size()}
                      Modified: ${changes.modified.size()}
                      Deleted: ${changes.deleted.size()}
                    --------------------------------------------------
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'rm -f consul jq || true'
            echo "Pipeline completed"
        }
        success {
            echo "✅ Configuration synchronization successful"
        }
        failure {
            echo "❌ Configuration synchronization failed"
        }
    }

}