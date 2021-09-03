# Overview

This folder contains a script for a learner to provision the workshop.

## Monolith Host

1. EC2 instance type = `t3.xlarge` as `Ubuntu Server 18.04`
1. Auto-assign Public IP = true
1. Opened ports = 80
1. 16GB storage
1. Initialized with these commands:

    ```
    sudo apt-get update
    sudo apt-get install -y git
    sudo mkdir -p /home/workshop
    sudo git clone https://github.com/dt-alliances-workshops/aws-modernization-dt-orders-setup.git /home/workshop/aws-modernization-dt-orders-setup
    sudo chown dtu_training:dtu_training -R /home/workshop
    sudo usermod -a -G sudo dtu_training
    sudo /home/workshop/aws-modernization-dt-orders-setup/provision-scripts/setup-host.sh dt-orders-monolith > /tmp/cloud-init-services.log
    ```

1. OneAgent installed as follows:

    `Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=dt-orders-monolith`

1. `LAB_NAME` value set to `MONOLITH` as well as the Dynatrace settings in the `/home/workshop/workshop-credentials.json` file.

## Services Host

1. EC2 instance type = `t3.xlarge` as `Ubuntu Server 18.04`
1. Auto-assign Public IP = true
1. Opened ports = 80
1. 16GB storage
1. Initialized with these commands:

    ```
    sudo apt-get update
    sudo apt-get install -y git
    sudo mkdir -p /home/workshop
    sudo git clone https://github.com/dt-alliances-workshops/aws-modernization-dt-orders-setup.git /home/workshop/aws-modernization-dt-orders-setup
    sudo chown dtu_training:dtu_training -R /home/workshop
    sudo usermod -a -G sudo dtu_training
    sudo /home/workshop/aws-modernization-dt-orders-setup/provision-scripts/setup-host.sh dt-orders-services > /tmp/cloud-init-services.log
    ```

1. OneAgent installed as follows:

    `Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=dt-orders-services`

1. `LAB_NAME` value set to `SERVICES` as well as the Dynatrace settings in the `/home/workshop/workshop-credentials.json` file (see below)