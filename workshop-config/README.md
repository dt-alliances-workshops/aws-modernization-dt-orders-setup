# Overview 

The folder contains scripts to setup the Dynatrace configuration for the learners Dynatrace tenant. 

The scripts use a combination of [Dynatrace Monitoring as Code](https://github.com/dynatrace-oss/dynatrace-monitoring-as-code) framework (a.k.a. monaco) and configuration using the [Dynatrace Configuration API](https://www.dynatrace.com/support/help/dynatrace-api/configuration-api/) for those few Dynatrace configurations not yet supported by monaco.  

# Usage

1. `setup-workshop-config.sh` will read `/home/ubuntu/workshop-credentials.json` file for Dynatrace URL and API token and set environment variables used by the scripts and expected by monaco.  This script calls monaco and the Dynatrace API to add or delete the configuration expected by the workshop.  This setup script will also download [Dynatrace monaco binary](https://github.com/dynatrace-oss/dynatrace-monitoring-as-code/releases)

1. `cleanup-workshop-config.sh` script will also call monaco and the Dynatrace API to remove the Dynatrace configuration from the tenant.
