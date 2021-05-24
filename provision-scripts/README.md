# Overview

This folder contains a script for a learner to provision the workshop.

A learner generally would not run any scripts within this repo.  The scripts and files used by the [Dynatrace Training University (DTU)](https://university.dynatrace.com)) provisioning scripts that pre-provision the workshop for each learner.

# Prerequisites

The two hosts are setup as follows:

## Monolith Host

1. EC2 instance type = `t3.xlarge` as `Ubuntu Server 20.04`
1. Auto-assign Public IP = true
1. Opened ports = 80
1. 16GB storage
1. Initialized with these commands:

    ```
    sudo apt-get update
    sudo apt-get install -y git
    sudo mkdir -p /home/dtu_training
    sudo git clone https://github.com/dt-alliances-workshops/aws-modernization-dt-orders-setup.git /home/dtu_training/aws-modernization-dt-orders-setup
    sudo chown dtu_training:dtu_training -R /home/dtu_training
    sudo usermod -a -G sudo dtu_training
    sudo /home/dtu_training/aws-modernization-dt-orders-setup/provision-scripts/setup-host.sh dt-orders-monolith > /tmp/cloud-init-services.log
    ```

1. OneAgent installed as follows:

    `/bin/sh /tmp/Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=dt-orders-monolith`

1. `LAB_NAME` value set to `MONOLITH` as well as the Dynatrace settings in the `/home/dtu_training/workshop-credentials.json` file.

## Services Host

1. EC2 instance type = `t3.xlarge` as `Ubuntu Server 20.04`
1. Auto-assign Public IP = true
1. Opened ports = 80
1. 16GB storage
1. Initialized with these commands:

    ```
    sudo apt-get update
    sudo apt-get install -y git
    sudo mkdir -p /home/dtu_training
    sudo git clone https://github.com/dt-alliances-workshops/aws-modernization-dt-orders-setup.git /home/dtu_training/aws-modernization-dt-orders-setup
    sudo chown dtu_training:dtu_training -R /home/dtu_training
    sudo usermod -a -G sudo dtu_training
    sudo /home/dtu_training/aws-modernization-dt-orders-setup/provision-scripts/setup-host.sh dt-orders-services > /tmp/cloud-init-services.log
    ```

1. OneAgent installed as follows:

    `/bin/sh /tmp/Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=dt-orders-services`

1. `LAB_NAME` value set to `SERVICES` as well as the Dynatrace settings in the `/home/dtu_training/workshop-credentials.json` file (see below)