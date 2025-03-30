# Config Reloader 👋

## Jenkinsfile for ConfigMap Deployment to HashiCorp Consul

This document provides instructions for developers on how to use the provided Jenkinsfile to deploy configuration maps to HashiCorp Consul.

## Branch Naming Convention

Your Git branches must adhere to the following naming convention: $env.$cluster.$application-config-map

Where:

* `$env`: Represents the environment (e.g., `dev`, `stg`, `prod`).
* `$cluster`: Represents the cluster name (e.g., `delhivery-dev-mumbai`, `delhivery-stg-hrms`).
* `$application-config-map`: Represents the application's config map name (e.g., `lead-management-config-map`, `hrms-config-map`).

**Example:**

* `dev.delhivery-dev-mumbai.lead-management-config-map`
* `stg.delhivery-stg-hrms.hrms-config-map`

## ConfigMap JSON File

Each branch must contain a `config-map-env.json` file at the root of the repository. This file should contain key-value pairs in JSON format, representing the configuration values for the application.

**Example `config-map-env.json`:**

```json
{
  "KEY_NAME_1": "VALUE_1",
  "KEY_NAME_2": "VALUE_2",
  // ... more key-value pairs
}