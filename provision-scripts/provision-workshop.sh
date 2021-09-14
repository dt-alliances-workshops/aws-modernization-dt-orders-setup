#!/bin/bash

CREDS_FILE="../gen/workshop-credentials.json"
if ! [ -f "$CREDS_FILE" ]; then
  echo "ERROR: missing $CREDS_FILE"
  exit 1
fi

# optional argument.  If not based, then the base workshop is setup.
# setup types are for additional features like kubernetes
SETUP_TYPE=$1

RESOURCE_PREFIX=$(cat $CREDS_FILE | jq -r '.RESOURCE_PREFIX')
DT_BASEURL=$(cat $CREDS_FILE | jq -r '.DT_BASEURL')
DT_PAAS_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_PAAS_TOKEN')
DT_API_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_API_TOKEN')
AWS_PROFILE=$(cat $CREDS_FILE | jq -r '.AWS_PROFILE')
AWS_REGION=$(cat $CREDS_FILE | jq -r '.AWS_REGION')

AWS_KEYPAIR_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"
STACK_NAME="$RESOURCE_PREFIX-dynatrace-modernize-workshop"
LOCAL_PEM_FILE="../gen/$RESOURCE_PREFIX-dynatrace-modernize-workshop.pem"

create_stack() 
{

  echo ""
  echo "-----------------------------------------------------------------------------------"
  echo "Creating CloudFormation Stack $STACK_NAME"
  echo "-----------------------------------------------------------------------------------"
  echo ""

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
  echo ""
  echo "-----------------------------------------------------------------------------------"
  echo "Adding AWS KeyPair $AWS_KEYPAIR_NAME"
  echo "-----------------------------------------------------------------------------------"
  echo ""

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
echo "About to Provision Workshop - $SETUP_TYPE"
echo "==================================================================="
read -p "Proceed? (y/n) : " REPLY;
if [ "$REPLY" != "y" ]; then exit 0; fi
echo ""
echo "=========================================="
echo "Provisioning workshop resources"
echo "Starting   : $(date)"
echo "=========================================="

case "$SETUP_TYPE" in
    "k8") 
        echo "Setup type = $SETUP_TYPE"
        setup_workshop_config k8
        ;;
    "services-vm") 
        echo "Setup type = $SETUP_TYPE"
        setup_workshop_config services-vm
        ;;
    *)
        echo "Setup type = base workshop"
        setup_workshop_config
        add_aws_keypair
        create_stack

        echo ""
        echo "Monitor CloudFormation stack status @ https://console.aws.amazon.com/cloudformation/home"
        echo ""
        ;;
esac

echo ""
echo "============================================="
echo "Provisioning workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""
