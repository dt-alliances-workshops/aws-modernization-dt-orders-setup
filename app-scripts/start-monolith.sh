#!/bin/bash

LOGFILE='/tmp/start-monolith.log' 
APP_SCRIPTS_PATH=/home/ubuntu/aws-modernization-dt-orders-setup/app-scripts
START_TIME="$(date)"

printf "\n\n***** Init Log ***\n" > $LOGFILE 2>&1
{ date ; whoami ; } >> $LOGFILE ; sudo chmod 555 $LOGFILE

printf "\n\n***** Stopping Monolith ***\n" >> $LOGFILE 2>&1
sudo $APP_SCRIPTS_PATH/stop-monolith.sh  >> $LOGFILE 2>&1

printf "\n\n***** Starting Monolith ***\n" >> $LOGFILE 2>&1
sudo docker-compose -f "$APP_SCRIPTS_PATH/docker-compose-monolith.yaml" up -d  >> $LOGFILE 2>&1

printf "\n\n***** Sleeping 20 seconds ***\n" >> $LOGFILE 2>&1
sleep 20

printf "\n\n***** Getting docker processes ***\n" >> $LOGFILE 2>&1
sudo docker ps >> $LOGFILE 2>&1

END_TIME="$(date)"
printf "\n\n" >> $LOGFILE 2>&1
printf "\n\nSTART_TIME: $START_TIME     END_TIME: $END_TIME" >> $LOGFILE 2>&1
