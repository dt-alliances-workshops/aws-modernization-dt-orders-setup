#!/bin/bash

LOGFILE='/tmp/start-services.log' 
APP_SCRIPTS_PATH=/home/dtu_training/aws-modernization-dt-orders-setup/app-scripts
START_TIME="$(date)"

printf "\n\n***** Init Log ***\n" > $LOGFILE 2>&1
{ date ; whoami ; } >> $LOGFILE ; sudo chmod 555 $LOGFILE

printf "\n\n***** Stopping Services ***\n" >> $LOGFILE 2>&1
sudo $APP_SCRIPTS_PATH/stop-services.sh

printf "\n\n***** Starting Services ***\n" >> $LOGFILE 2>&1
sudo docker-compose -f "$APP_SCRIPTS_PATH/docker-compose-services.yaml" up -d

END_TIME="$(date)"
printf "\n\n" >> $LOGFILE 2>&1
printf "\n\nSTART_TIME: $START_TIME     END_TIME: $END_TIME" >> $LOGFILE 2>&1
