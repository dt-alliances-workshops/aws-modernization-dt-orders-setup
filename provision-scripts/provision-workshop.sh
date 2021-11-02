#!/bin/bash

DT_BASEURL=$1
DT_API_TOKEN=$2

if [ -z $DT_BASEURL ]; then
  echo "ABORT: missing DT_BASEURL parameter"
  exit 1
fi

if [ -z $DT_API_TOKEN ]; then
  echo "ABORT: missing DT_API_TOKEN parameter"
  exit 1
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
  cd ../provision-scripts
}

create_aws_resources() {
  
  echo "Create AWS resource: monolith-vm"
  aws cloudformation create-stack \
      --stack-name monolith-vm \
      --template-body file://cloud-formation/workshopMonolith.json \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN

  echo "Create AWS resource: services-vm"
  aws cloudformation create-stack \
      --stack-name services-vm \
      --template-body file://cloud-formation/workshopServices.json \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN

}

echo "==================================================================="
echo "About to Provision Workshop for:"
echo "$DT_BASEURL"
echo "==================================================================="
read -p "Proceed? (y/n) : " REPLY;
if [ "$REPLY" != "y" ]; then exit 0; fi
echo ""
echo "=========================================="
echo "Provisioning workshop resources"
echo "Starting   : $(date)"
echo "=========================================="

make_creds_file
setup_workshop_config
create_aws_resources

echo ""
echo "============================================="
echo "Provisioning workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""