# Overview

This folder contains a script for a learner to provision the workshop

# CloudFormation

The `cloud-formation` folder has two CloudFormation scripts that each provision a VPC with a EC2 instance that installs the OneAgent and sample application at startup. The AMI images for EC2 are based on this instance:  

```
# Community AMI
Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2021-04-30
```

A RegionMap within the CloudFormation scripts have several regions and each region has a unique AMI. If your region is not in the map, then pick a new region of adjust the script with the AMI in your region. 

# Provisioning

The `provision-workshop.sh` script can be called to automatically apply the workshop Dynatrace configuration and create AWS stacks for the two CloudFormation scripts in the `cloud-formation` folder.

One must have AWS CLI and pass in the Dynatrace URL and Token with required permissions for workshop Dynatrace configuration and OneAgent download and installation.

See the comments within the `provision-workshop.sh` for the optional arguments for EC2 KeyPair name and to provision one or both EC2 instances.  

# Useful commands

```
# Oneagent status
sudo systemctl status oneagent

# EC2 user data logs
ls -l /var/log/cloud-init*.log

# App startup up logs
ls -l /tmp/*log

# Application status
sudo docker ps

```