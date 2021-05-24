#!/bin/bash

LOGFILE='/tmp/start-monolith.log' 
APP_SCRIPTS_PATH=/home/dtu_training/aws-modernization-dt-orders-setup/app-scripts
START_TIME="$(date)"

printf "\n\n***** Init Log ***\n" > $LOGFILE 2>&1
{ date ; whoami ; } >> $LOGFILE ; sudo chmod 555 $LOGFILE

printf "\n\n***** Stopping Monolith ***\n" >> $LOGFILE 2>&1
sudo $APP_SCRIPTS_PATH/stop-monolith.sh

printf "\n\n***** Starting Monolith ***\n" >> $LOGFILE 2>&1
sudo docker-compose -f "$APP_SCRIPTS_PATH/docker-compose-monolith.yaml" up -d

END_TIME="$(date)"
printf "\n\n" >> $LOGFILE 2>&1
printf "\n\nSTART_TIME: $START_TIME     END_TIME: $END_TIME" >> $LOGFILE 2>&1
