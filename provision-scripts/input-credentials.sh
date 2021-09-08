#!/bin/bash

YLW='\033[1;33m'
NC='\033[0m'

CREDS_TEMPLATE_FILE="./workshop-credentials.template"
CREDS_FILE="../gen/workshop-credentials.json"

if [ -f "$CREDS_FILE" ]
then
    DT_BASEURL=$(cat $CREDS_FILE | jq -r '.DT_BASEURL')
    DT_API_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_API_TOKEN')
    DT_PAAS_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_PAAS_TOKEN')
    DT_ENVIRONMENT_ID=$(cat $CREDS_FILE | jq -r '.DT_ENVIRONMENT_ID')
    RESOURCE_PREFIX=$(cat $CREDS_FILE | jq -r '.RESOURCE_PREFIX')
fi

clear
echo "==================================================================="
echo -e "${YLW}Please enter your Dynatrace credentials as requested below: ${NC}"
echo "Press <enter> to keep the current value"
echo "==================================================================="
echo "Your last name - Max 10 characters:"
read -p "                         (current: $RESOURCE_PREFIX) : " RESOURCE_PREFIX_NEW
echo    "Dynatrace Base URL - example https://ABC.live.dynatrace.com"
read -p "                         (current: $DT_BASEURL) : " DT_BASEURL_NEW
read -p "Dynatrace PaaS Token     (current: $DT_PAAS_TOKEN) : " DT_PAAS_TOKEN_NEW
read -p "Dynatrace API Token      (current: $DT_API_TOKEN) : " DT_API_TOKEN_NEW
echo "==================================================================="
echo ""

# set value to new input or default to current value
RESOURCE_PREFIX=${RESOURCE_PREFIX_NEW:-$RESOURCE_PREFIX}
DT_BASEURL=${DT_BASEURL_NEW:-$DT_BASEURL}
DT_API_TOKEN=${DT_API_TOKEN_NEW:-$DT_API_TOKEN}
DT_PAAS_TOKEN=${DT_PAAS_TOKEN_NEW:-$DT_PAAS_TOKEN}

# pull out the DT_ENVIRONMENT_ID. DT_BASEURL will be one of these patterns
if [[ $(echo $DT_BASEURL | grep "/e/" | wc -l) == *"1"* ]]; then
  #echo "Matched pattern: https://{your-domain}/e/{your-environment-id}"
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"/e/" '{ print $2 }')
elif [[ $(echo $DT_BASEURL | grep ".live." | wc -l) == *"1"* ]]; then
  #echo "Matched pattern: https://{your-environment-id}.live.dynatrace.com"
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
elif [[ $(echo $DT_BASEURL | grep ".sprint." | wc -l) == *"1"* ]]; then
  #echo "Matched pattern: https://{your-environment-id}.sprint.dynatracelabs.com"
  DT_ENVIRONMENT_ID=$(echo $DT_BASEURL | awk -F"." '{ print $1 }' | awk -F"https://" '{ print $2 }')
else
  echo "ERROR: No DT_ENVIRONMENT_ID pattern match to $DT_BASEURL"
  exit 1
fi

#remove trailing / if the have it
if [ "${DT_BASEURL: -1}" == "/" ]; then
  echo "removing / from DT_BASEURL"
  DT_BASEURL="$(echo ${DT_BASEURL%?})"
fi

echo -e "Please confirm all are correct:"
echo "--------------------------------------------------"
echo "Your last name           : $RESOURCE_PREFIX"
echo "Dynatrace Base URL       : $DT_BASEURL"
echo "Dynatrace PaaS Token     : $DT_PAAS_TOKEN"
echo "Dynatrace API Token      : $DT_API_TOKEN"
echo "--------------------------------------------------"
echo "derived values"
echo "--------------------------------------------------"
echo "Dynatrace Environment ID : $DT_ENVIRONMENT_ID"
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
  sed 's~RESOURCE_PREFIX_PLACEHOLDER~'"$RESOURCE_PREFIX"'~' | \
  sed 's~DT_ENVIRONMENT_ID_PLACEHOLDER~'"$DT_ENVIRONMENT_ID"'~' | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN"'~' | \
  sed 's~DT_PAAS_TOKEN_PLACEHOLDER~'"$DT_PAAS_TOKEN"'~' > $CREDS_FILE

echo "Saved credential to: $CREDS_FILE"

cat $CREDS_FILE
