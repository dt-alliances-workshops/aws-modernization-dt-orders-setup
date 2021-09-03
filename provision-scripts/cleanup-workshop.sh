#!/bin/bash

CREDS_FILE="../gen/workshop-credentials.json"
if ! [ -f "$CREDS_FILE" ]; then
  echo "ERROR: missing $CREDS_FILE"
  exit 1
fi

AWS_PROFILE=$(cat creds.json | jq -r '.AWS_PROFILE')
AWS_REGION=$(cat creds.json | jq -r '.AWS_REGION')
AWS_KEYPAIR_NAME=$(cat creds.json | jq -r '.AWS_KEYPAIR_NAME')
RESOURCE_PREFIX=$(cat creds.json | jq -r '.RESOURCE_PREFIX')

AWS_KEYPAIR_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"
STACK_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"

delete_keypair()
{
  KEYPAIR_NAME=$1
  echo ""
  echo "-----------------------------------------------------------------------------------"
  echo "Checking to see if $KEYPAIR_NAME exists"
  echo "-----------------------------------------------------------------------------------"

  # delete the keypair needed for ec2 if it exists
  KEY=$(aws ec2 describe-key-pairs \
    --region $AWS_REGION | grep $AWS_KEYPAIR_NAME)
  if [ -z "$KEY" ]; then
    echo ""
    echo "Skipping, delete key-pair $KEYPAIR_NAME since it does not exists"
  else
    echo "Deleting $KEYPAIR_NAME ($INSTANCE_ID)"
    aws ec2 delete-key-pair \
      --key-name $KEYPAIR_NAME \
      --region $AWS_REGION
  fi

  sudo rm gen/*.pem
}

delete_stack()
{
  echo ""
  echo "-----------------------------------------------------------------------------------"
  echo "Reqesting CloudFormation Delete Stack $STACK_NAME"
  echo "-----------------------------------------------------------------------------------"

  aws cloudformation delete-stack \
      --stack-name $STACK_NAME \
      --region $AWS_REGION

  echo ""
  echo "Monitor CloudFormation stack status @ https://console.aws.amazon.com/cloudformation/home"
  echo ""
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

  delete_keypair $AWS_KEYPAIR_NAME
  delete_stack

  echo "==================================================================================="
  echo "Cleaning Up AWS workshop resources COMPLETE"
  echo "End: $(date)"
  echo "============================================="

fi
