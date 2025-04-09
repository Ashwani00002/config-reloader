<div align="center">
  <img src="https://img.shields.io/badge/Jenkins-Pipeline-blue?style=for-the-badge&logo=jenkins" alt="Jenkins Pipeline">
  <img src="https://img.shields.io/badge/Consul-KV%20Store-yellow?style=for-the-badge&logo=hashicorp" alt="Consul KV Store">
</div>

<br/>

# 🚀 Automated DEX Configuration Sync to Consul via Jenkins

This project provides a streamlined and automated Jenkins pipeline to synchronize Data Exchange (DEX) configurations stored within your application repository directly to a Consul key-value store. By adhering to a simple branching strategy and modifying the `dex-config.json` file, you can effortlessly manage your application's environment-specific settings in Consul.

## ✨ Key Features

* **Branch-Based Environment Management:** Automatically checks out or creates a branch based on the `$ENV_$BU/$Team/$Application` nomenclature (e.g., `PRD_Transport/UMS/LeadMgmt`).
* **Declarative Configuration:** All DEX configurations are managed within the `dex-config.json` file located in your application branch.
* **Selective Updates:** Only the environment variables corresponding to the modified `$SOURCE_CONNECTOR`, `$TASK_CONNECTOR`, or `$SINK_CONNECTOR` sections in `dex-config.json` are updated in Consul.
* **Automated Trigger:** Any changes committed to the `dex-config.json` file in a designated environment branch will automatically trigger the Jenkins job.
* **Consul Integration:** Seamlessly creates, updates and delete key:value in Consul KV store from `dex-config.json`
* **Clear Console Output:** Provides informative console logs during the Jenkins job execution.

## ⚙️ How It Works

1.  **Branching Strategy:** Your application repository should follow a branching convention where each environment has its own branch named according to the pattern `$ENV_$BU/$Team/$Application`. For example:
    * `PRD_Transport/UMS/LeadMgmt` for the production environment of the Lead Management application within the UMS team of the Transport BU.
    * `STG_ABC/LMS/WMSSystem` for the staging environment of the WMS System within the LMS team of the ABC BU.

2.  **`dex-config.json`:** Each environment branch contains a `dex-config.json` file at the root level. This file holds the configuration for your application's connectors.

    ```json
    {
      "BU": "TRANSPORT",
      "Team": "UMS",
      "Application": "LeadMgmt",
      "env": "PRD",
      "SOURCE_CONNECTOR": {
        "Kafka" : {
          "BROKER_URL": "<kafka-broker-url>",
          "TOPIC": "<kafka_topic>",
          "CONSUMER_GROUP": "<kafka-consumer-group>"
        }
      },
      "TASK_CONNECTOR": {
        "HTTP": {
          "ADAPTOR_URL": "<HTTP_URL>",
          "ADAPTOR_HOST": "<HTTP_HOSTNAME>"
        }
      },
      "SINK_CONNECTOR": {
        "DynamoDB": {
          "URL": "<DynamoDB_URL>",
          "HOST": "<HTTP_DynamoDB_HOST>",
          "REGION": "ap-south-1"
        }
      }
    }
    ```

3.  **Jenkins Automation:**
    * The automation job in Jenkins is triggered using `Jenkinsfile` within your repository. Any changes made to `dex-config.json`, trigger a Jenkins job.
    * It then reads the `dex-config.json` file to extract the environment details (`env`, `BU`, `Team`, `Application`) and the connector configurations.
    * Based on these details, it constructs the base prefix in Consul (e.g., `PRD_Transport/UMS/LeadMgmt`).
    * For each nested connector (`SOURCE_CONNECTOR`, `TASK_CONNECTOR`, `SINK_CONNECTOR`) and its key-value pairs in `dex-config.json`, the pipeline creates or updates the corresponding keys in Consul under the determined prefix. For the example above, the following Consul keys would be created:

        ```
        PRD_Transport/UMS/LeadMgmt/SOURCE_CONNECTOR/Kafka/BROKER_URL <kafka-broker-url>
        PRD_Transport/UMS/LeadMgmt/SOURCE_CONNECTOR/Kafka/TOPIC <kafka_topic>
        PRD_Transport/UMS/LeadMgmt/SOURCE_CONNECTOR/Kafka/CONSUMER_GROUP <kafka-consumer-group>
        PRD_Transport/UMS/LeadMgmt/TASK_CONNECTOR/HTTP/ADAPTOR_URL <HTTP_URL>
        PRD_Transport/UMS/LeadMgmt/TASK_CONNECTOR/HTTP/ADAPTOR_HOST <HTTP_HOSTNAME>
        PRD_Transport/UMS/LeadMgmt/SINK_CONNECTOR/DynamoDB/URL <DynamoDB_URL>
        PRD_Transport/UMS/LeadMgmt/SINK_CONNECTOR/DynamoDB/HOST <HTTP_DynamoDB_HOST>
        PRD_Transport/UMS/LeadMgmt/SINK_CONNECTOR/DynamoDB/REGION ap-south-1
        ```

    * If you add, modify, or delete environment variables within the nested connector sections of `dex-config.json` and commit the changes, the Jenkins job will automatically update Consul accordingly.

## 🚀 Getting Started

1. **Branching:** Adhere to the `$ENV_$BU/$Team/$Application` branching strategy in your repository.
2.  **`dex-config.json`:** Place a `dex-config.json` file at the root of each environment branch containing your DEX configurations.
3.  **`Jenkinsfile`:** Ensure the provided `Jenkinsfile` is also present at the root of your repository.

## 💡 Usage

Simply make changes to the environment variables within the `$SOURCE_CONNECTOR`, `$TASK_CONNECTOR`, or `$SINK_CONNECTOR` sections of the `dex-config.json` file in your specific environment branch and commit the changes. The Jenkins job will be automatically triggered and will synchronize these changes to your Consul key-value store.

This automation streamlines the management of your application's environment-specific configurations, ensuring consistency and reducing manual intervention.