#!/bin/bash

DT_BASEURL=$1
DT_API_TOKEN=$2
DASHBOARD_OWNER_EMAIL=$3  # required is making monaco dashboards SETUP_TYPE=all.  
                          # Otherwise optional or any "dummy" value if you need to pass
                          # in SETUP_TYPE and KEYPAIR_NAME parameters
SETUP_TYPE=$4             # optional argument. values are: all, monolith-vm, services-vm.  default is all
                          # this allows to just recreate the cloudformation stack is one VM stack fails
KEYPAIR_NAME=$5           # optional argument. if leave blank it will default to ee-default-keypair
                          # this allows to override for testing outside of AWS event engine account

if [ -z $DT_BASEURL ]; then
  echo "ABORT: missing DT_BASEURL parameter"
  exit 1
fi

if [ -z $DT_API_TOKEN ]; then
  echo "ABORT: missing DT_API_TOKEN parameter"
  exit 1
fi

if [ -z $SETUP_TYPE ]; then
  SETUP_TYPE=all
fi

if [ -z $KEYPAIR_NAME ]; then
  KEYPAIR_NAME=ee-default-keypair
fi

make_creds_file() {

  CREDS_TEMPLATE_FILE="./workshop-credentials.template"
  CREDS_FILE="../gen/workshop-credentials.json"
  echo "Making $CREDS_FILE"

  HOSTNAME_MONOLITH=dt-orders-monolith
  HOSTNAME_SERVICES=dt-orders-services
  CLUSTER_NAME=dynatrace-workshop-cluster

  cat $CREDS_TEMPLATE_FILE | \
  sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
  sed 's~HOSTNAME_MONOLITH_PLACEHOLDER~'"$HOSTNAME_MONOLITH"'~' | \
  sed 's~HOSTNAME_SERVICES_PLACEHOLDER~'"$HOSTNAME_SERVICES"'~' | \
  sed 's~CLUSTER_NAME_PLACEHOLDER~'"$CLUSTER_NAME"'~' | \
  sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN"'~' > $CREDS_FILE

}

setup_workshop_config() {

  echo "Setup workshop config"
  cd ../workshop-config
  ./setup-workshop-config.sh monolith-vm
  ./setup-workshop-config.sh services-vm
  ./setup-workshop-config.sh dashboard $DASHBOARD_OWNER_EMAIL
  cd ../provision-scripts
}

get_availability_zone() {

  MY_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]') 
  INSTANCE_TYPE=m5.xlarge
  AVAILABILITY_ZONE=$(aws ec2 describe-instance-type-offerings \
      --location-type "availability-zone" \
      --filters Name=instance-type,Values=$INSTANCE_TYPE \
      --output json) | jq -r '.InstanceTypeOfferings[0].Location')

  if [ -z $AVAILABILITY_ZONE ]; then
    echo "ABORT: No $INSTANCE_TYPE available in $MY_REGION."
    exit 1
  else
    echo "Found $INSTANCE_TYPE available in $MY_REGION. Using AVAILABILITY_ZONE $AVAILABILITY_ZONE" 
  fi
}

create_aws_monolith-vm() {

  echo "Create AWS resource: monolith-vm"
  aws cloudformation create-stack \
      --stack-name "monolith-vm-$(date +%s)" \
      --template-body file://cloud-formation/workshopMonolith.yaml \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN \
        ParameterKey=KeyPairName,ParameterValue=$KEYPAIR_NAME \
        ParameterKey=AvailabilityZone,ParameterValue=$AVAILABILITY_ZONE
}

create_aws_services-vm() {

  echo "Create AWS resource: services-vm"
  aws cloudformation create-stack \
      --stack-name "services-vm-$(date +%s)" \
      --template-body file://cloud-formation/workshopServices.yaml \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN \
        ParameterKey=ResourcePrefix,ParameterValue="" \
        ParameterKey=KeyPairName,ParameterValue=$KEYPAIR_NAME \
        ParameterKey=AvailabilityZone,ParameterValue=$AVAILABILITY_ZONE
}

echo "==================================================================="
echo "About to Provision Workshop for:"
echo "$DT_BASEURL"
echo "SETUP_TYPE   = $SETUP_TYPE"
echo "KEYPAIR_NAME = $KEYPAIR_NAME"
echo "==================================================================="
read -p "Proceed? (y/n) : " REPLY;
if [ "$REPLY" != "y" ]; then exit 0; fi
echo ""
echo "=========================================="
echo "Provisioning workshop resources"
echo "Starting   : $(date)"
echo "=========================================="

get_availability_zone
case "$SETUP_TYPE" in
    "monolith-vm") 
        create_aws_monolith-vm
        ;;
    "services-vm") 
        create_aws_services-vm
        ;;
    *)
        make_creds_file
        setup_workshop_config
        create_aws_monolith-vm
        create_aws_services-vm
        ;;
esac

echo ""
echo "============================================="
echo "Provisioning workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""