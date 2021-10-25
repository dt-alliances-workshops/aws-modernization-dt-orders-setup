#!/bin/bash

YLW='\033[1;33m'
NC='\033[0m'

CREDS_TEMPLATE_FILE="./workshop-credentials.template"
CREDS_FILE="../gen/workshop-credentials.json"

if [ -f "$CREDS_FILE" ]
then
    DT_BASEURL=$(cat $CREDS_FILE | jq -r '.DT_BASEURL')
    DT_API_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_API_TOKEN')
    HOSTNAME_MONOLITH=$(cat $CREDS_FILE | jq -r '.HOSTNAME_MONOLITH')
    HOSTNAME_SERVICES=$(cat $CREDS_FILE | jq -r '.HOSTNAME_SERVICES')
    CLUSTER_NAME=$(cat $CREDS_FILE | jq -r '.CLUSTER_NAME')
else
    # set the defaults
    HOSTNAME_MONOLITH=dt-orders-monolith
    HOSTNAME_SERVICES=dt-orders-services
    CLUSTER_NAME=dynatrace-workshop-cluster
fi

clear
echo "==================================================================="
echo -e "${YLW}Please enter your Dynatrace credentials as requested below: ${NC}"
echo "Press <enter> to keep the current value"
echo "==================================================================="
echo    "Dynatrace Base URL - example https://ABC.live.dynatrace.com"
read -p "                         (current: $DT_BASEURL) : " DT_BASEURL_NEW
read -p "Dynatrace API Token      (current: $DT_API_TOKEN) : " DT_API_TOKEN_NEW
echo "==================================================================="
echo "ONLY adjust these IF you added a PREFIX CloudFormation stack parameter"
echo "==================================================================="
read -p "Monolith Host Name       (current: $HOSTNAME_MONOLITH) : " HOSTNAME_MONOLITH_NEW
read -p "Services Host Name       (current: $HOSTNAME_SERVICES) : " HOSTNAME_SERVICES_NEW
read -p "Cluster Name             (current: $CLUSTER_NAME) : " CLUSTER_NAME_NEW
echo "==================================================================="
echo ""

# set value to new input or default to current value
DT_BASEURL=${DT_BASEURL_NEW:-$DT_BASEURL}
DT_API_TOKEN=${DT_API_TOKEN_NEW:-$DT_API_TOKEN}
HOSTNAME_MONOLITH=${HOSTNAME_MONOLITH_NEW:-$HOSTNAME_MONOLITH}
HOSTNAME_SERVICES=${HOSTNAME_SERVICES_NEW:-$HOSTNAME_SERVICES}
CLUSTER_NAME=${CLUSTER_NAME_NEW:-$CLUSTER_NAME}

#remove trailing / if the have it
if [ "${DT_BASEURL: -1}" == "/" ]; then
  echo "removing / from DT_BASEURL"
  DT_BASEURL="$(echo ${DT_BASEURL%?})"
fi

echo -e "Please confirm all are correct:"
echo "--------------------------------------------------"
echo "Dynatrace Base URL       : $DT_BASEURL"
echo "Dynatrace API Token      : $DT_API_TOKEN"
echo "--------------------------------------------------"
echo "Monolith Host Name       : $HOSTNAME_MONOLITH"
echo "Services Host Name       : $HOSTNAME_SERVICES"
echo "Cluster Name             : $CLUSTER_NAME"
echo "==================================================================="
read -p "Is this all correct? (y/n) : " REPLY;
if [ "$REPLY" != "y" ]; then exit 0; fi
echo ""
echo "==================================================================="
# make a backup
cp $CREDS_FILE $CREDS_FILE.bak 2> /dev/null
rm $CREDS_FILE 2> /dev/null

# create new file from the template
cat $CREDS_TEMPLATE_FILE | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
  sed 's~HOSTNAME_MONOLITH_PLACEHOLDER~'"$HOSTNAME_MONOLITH"'~' | \
  sed 's~HOSTNAME_SERVICES_PLACEHOLDER~'"$HOSTNAME_SERVICES"'~' | \
  sed 's~CLUSTER_NAME_PLACEHOLDER~'"$CLUSTER_NAME"'~' | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN"'~' > $CREDS_FILE

echo "Saved credential to: $CREDS_FILE"

cat $CREDS_FILE
