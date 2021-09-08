#!/bin/bash

CREDS_FILE="../gen/workshop-credentials.json"
if ! [ -f "$CREDS_FILE" ]; then
  echo "ERROR: missing $CREDS_FILE"
  exit 1
fi

RESOURCE_PREFIX=$(cat $CREDS_FILE | jq -r '.RESOURCE_PREFIX')
DT_BASEURL=$(cat $CREDS_FILE | jq -r '.DT_BASEURL')
DT_PAAS_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_PAAS_TOKEN')
DT_API_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_API_TOKEN')
AWS_PROFILE=$(cat $CREDS_FILE | jq -r '.AWS_PROFILE')
AWS_REGION=$(cat $CREDS_FILE | jq -r '.AWS_REGION')

AWS_KEYPAIR_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"
STACK_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"
LOCAL_PEM_FILE="../gen/dynatrace-modernize-workshop.pem"

create_stack() 
{

  echo ""
  echo "-----------------------------------------------------------------------------------"
  echo "Creating CloudFormation Stack $STACK_NAME"
  echo "-----------------------------------------------------------------------------------"

  aws cloudformation create-stack \
      --stack-name $STACK_NAME \
      --region $AWS_REGION \
      --template-body file://workshopCloudFormationTemplate.yaml \
      --parameters \
          ParameterKey=KeyName,ParameterValue=$AWS_KEYPAIR_NAME \
          ParameterKey=LastName,ParameterValue=$RESOURCE_PREFIX \
          ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
          ParameterKey=DynatracePaasToken,ParameterValue=$DT_PAAS_TOKEN \
      --capabilities CAPABILITY_NAMED_IAM
}

setup_workshop_config()
{
    # this scripts will add workshop config like tags, dashboard, MZ
    # need to change directories so that the generated monaco files
    # are in the right folder
    cd ../workshop-config
    ./setup-workshop-config.sh $1
    cd ../provision-scripts
}

add_aws_keypair()
{
  # add the keypair needed for ec2 if it does not exist
  KEY=$(aws ec2 describe-key-pairs \
    --region $AWS_REGION | grep $AWS_KEYPAIR_NAME)
  if [ -z "$KEY" ]; then
    echo "Creating a keypair named $AWS_KEYPAIR_NAME for the ec2 instances"
    echo "Saving output to $LOCAL_PEM_FILE"
    aws ec2 create-key-pair \
      --key-name $AWS_KEYPAIR_NAME \
      --region $AWS_REGION \
      --query 'KeyMaterial' \
      --output text > $LOCAL_PEM_FILE

    # adjust permissions required for ssh
    chmod 400 $LOCAL_PEM_FILE
  else
    echo "Skipping, add key-pair $AWS_KEYPAIR_NAME since it exists"
  fi
}

############################################################
echo "==================================================================="
echo "About to provision AWS workshop resources"
echo ""
echo "1) Add Dynatrace configuration to: $DT_BASEURL"
echo "2) Add AWS keypair: $AWS_KEYPAIR_NAME"
echo "3) Create AWS CLoudformation stack: $STACK_NAME"
echo "==================================================================="
read -p "Proceed with creation? (y/n) : " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then

  echo ""
  echo "=========================================="
  echo "Provisioning AWS workshop resources"
  echo "Starting: $(date)"
  echo "=========================================="

  setup_workshop_config
  add_aws_keypair
  create_stack

  echo ""
  echo "============================================="
  echo "Provisioning AWS workshop resources COMPLETE"
  echo "End: $(date)"
  echo "============================================="
  echo ""
  echo "Monitor CloudFormation stack status @ https://console.aws.amazon.com/cloudformation/home"
  
fi