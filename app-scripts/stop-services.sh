#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "ERROR: script must be run as root or with sudo"
   exit 1
fi

APP_SCRIPTS_PATH=/home/ubuntu/aws-modernization-dt-orders-setup/app-scripts

echo "*** Stopping Services ***"
sudo docker-compose -f "$APP_SCRIPTS_PATH/docker-compose-services.yaml" down

echo "*** Stopping Services Done. ***"