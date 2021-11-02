# Overview

This folder contains a script for a learner to provision the workshop

# CloudFormation

The AMI images for EC2 are based on this model.  

```
Ubuntu Server 20.04 LTS (HVM), SSD Volume Type x86
```

A RegionMap has several regions and each region has a unique AMI. If your region is not in the map, then pick a new region of adjust the script with the AMI in your region. 

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