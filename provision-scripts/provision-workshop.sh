#!/bin/bash

DT_BASEURL=$1
DT_API_TOKEN=$2
SETUP_TYPE=$3     # optional argument. if leave blank it will default
KEYPAIR_NAME=$4   # optional argument. if leave blank it will default

if [ -z $DT_BASEURL ]; then
  echo "ABORT: missing DT_BASEURL parameter"
  exit 1
fi

if [ -z $DT_API_TOKEN ]; then
  echo "ABORT: missing DT_API_TOKEN parameter"
  exit 1
fi

if [ -z $SETUP_TYPE ]; then
  SETUP_TYPE=ALL
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
  cd ../provision-scripts
}

create_aws_monolith-vm() {

  echo "Create AWS resource: monolith-vm"
  aws cloudformation create-stack \
      --stack-name "monolith-vm-$(date +%s)" \
      --template-body file://cloud-formation/workshopMonolith.yaml \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN \
        ParameterKey=KeyPairName,ParameterValue=$KEYPAIR_NAME
}

create_aws_services-vm() {

  echo "Create AWS resource: services-vm"
  aws cloudformation create-stack \
      --stack-name "services-vm-$(date +%s)" \
      --template-body file://cloud-formation/workshopServices.yaml \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN \
        ParameterKey=ResourcePrefix,ParameterValue="" \
        ParameterKey=KeyPairName,ParameterValue=$KEYPAIR_NAME
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