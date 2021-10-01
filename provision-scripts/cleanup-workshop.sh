#!/bin/bash

CREDS_FILE="../gen/workshop-credentials.json"
if ! [ -f "$CREDS_FILE" ]; then
  echo "ERROR: missing $CREDS_FILE"
  exit 1
fi

AWS_KEYPAIR_NAME=$(cat $CREDS_FILE | jq -r '.AWS_KEYPAIR_NAME')
RESOURCE_PREFIX=$(cat $CREDS_FILE | jq -r '.RESOURCE_PREFIX')

AWS_KEYPAIR_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"

delete_keypair()
{
  KEYPAIR_NAME=$1
  echo ""
  echo "-----------------------------------------------------------------------------------"
  echo "Checking to see if $KEYPAIR_NAME exists"
  echo "-----------------------------------------------------------------------------------"

  # delete the keypair needed for ec2 if it exists
  KEY=$(aws ec2 describe-key-pairs | grep $AWS_KEYPAIR_NAME)
  if [ -z "$KEY" ]; then
    echo ""
    echo "Skipping, delete key-pair $KEYPAIR_NAME since it does not exists"
  else
    echo "Deleting $KEYPAIR_NAME ($INSTANCE_ID)"
    aws ec2 delete-key-pair \
      --key-name $KEYPAIR_NAME
  fi

  sudo rm -f ../gen/*.pem
}

cleanup_workshop_config()
{
    # this scripts will add workshop config like tags, dashboard, MZ
    # need to change directories so that the generated monaco files
    # are in the right folder
    cd ../workshop-config
    ./cleanup-workshop-config.sh Y
    cd ../provision-scripts
}

#*********************************

echo "==================================================================="
echo "About to Cleaning Up AWS workshop resources"
echo ""
echo "1) Delete AWS keypair: $AWS_KEYPAIR_NAME"
echo "2) Delete AWS CLoudformation stack: $STACK_NAME"
echo "==================================================================="
read -p "Proceed with cleanup? (y/n) : " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then

  echo "==================================================================================="
  echo "Cleaning Up AWS workshop resources"
  echo "Starting: $(date)"
  echo "==================================================================================="

  cleanup_workshop_config
  delete_keypair $AWS_KEYPAIR_NAME

  echo "==================================================================================="
  echo "Cleaning Up AWS workshop resources COMPLETE"
  echo "End: $(date)"
  echo "============================================="

fi
