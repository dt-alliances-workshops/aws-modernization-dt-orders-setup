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
  ./setup-workshop-config.sh cluster
  ./setup-workshop-config.sh dashboard $DASHBOARD_OWNER_EMAIL
  cd ../provision-scripts
}

get_availability_zone() {

  MY_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]') 
  INSTANCE_TYPE=m5.xlarge
  AVAILABILITY_ZONE=$(aws ec2 describe-instance-type-offerings --location-type "availability-zone" --filters Name=instance-type,Values=$INSTANCE_TYPE | jq -r '.InstanceTypeOfferings[0].Location')

  if [ -z $AVAILABILITY_ZONE ]; then
    echo "ABORT: No $INSTANCE_TYPE available in $MY_REGION."
    exit 1
  else
    echo "Found $INSTANCE_TYPE available in $MY_REGION. Using AVAILABILITY_ZONE $AVAILABILITY_ZONE" 
  fi
}

get_aws_acct_id(){
    AWS_ACCT_ID=$(aws sts get-caller-identity --query "Account" --output text)
}

get_dt_external_id(){
	DT_EXT_ID=$(curl -s --request GET --url $DT_BASEURL/api/config/v1/aws/iamExternalId --header "Authorization: Api-Token $DT_API_TOKEN" | jq --raw-output '.token')
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

create_aws_activegate_role-vm() {

  echo "Create AWS resource: activegate-vm"
  aws cloudformation create-stack \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name "activegate-vm-$(date +%s)" \
      --template-body file://cloud-formation/workshopActiveGate-createrole.yaml \
      --parameters ParameterKey=DynatraceBaseURL,ParameterValue=$DT_BASEURL \
        ParameterKey=DynatracePaasToken,ParameterValue=$DT_API_TOKEN \
        ParameterKey=ResourcePrefix,ParameterValue="" \
        ParameterKey=KeyPairName,ParameterValue=$KEYPAIR_NAME \
        ParameterKey=AvailabilityZone,ParameterValue=$AVAILABILITY_ZONE \
        ParameterKey=ActiveGateRoleName,ParameterValue=Dynatrace_ActiveGate_role \
        ParameterKey=AssumePolicyName,ParameterValue=Dynatrace_assume_policy \
        ParameterKey=MonitoringRoleName,ParameterValue=Dynatrace_monitoring_role \
        ParameterKey=MonitoredAccountID,ParameterValue=$AWS_ACCT_ID
}

create_aws_role_based_access_monitoredaccount() {

    aws cloudformation create-stack \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name "rolebased-ag-monitoredaccount-$(date +%s)" \
      --template-body file://cloud-formation/role_based_access_monitored_account_template.yml \
      --parameters ParameterKey=ExternalID,ParameterValue=$DT_EXT_ID \
        ParameterKey=ActiveGateRoleName,ParameterValue=Dynatrace_ActiveGate_role \
        ParameterKey=ActiveGateAccountID,ParameterValue=$AWS_ACCT_ID \
        ParameterKey=RoleName,ParameterValue=Dynatrace_monitoring_role \
        ParameterKey=PolicyName,ParameterValue=Dynatrace_monitoring_policy
}

create_dt_aws(){
    curl -X POST \
    $DT_BASEURL/api/config/v1/aws/credentials \
    -H "accept: application/json; charset=utf-8" \
    -H "Authorization: Api-Token $DT_API_TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "{
      \"label\": \"ImmersionDay Workshop\",
      \"partitionType\": \"AWS_DEFAULT\",
      \"authenticationData\": {
        \"type\": \"ROLE\",
        \"roleBasedAuthentication\": {
          \"iamRole\": \"Dynatrace_monitoring_role\",
          \"accountId\": \"$AWS_ACCT_ID\"
        }
      },
      \"taggedOnly\": false
    }"
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
echo "Setup type : $SETUP_TYPE"
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
        create_aws_monolith-vm
        create_aws_services-vm
        
        get_aws_acct_id
        get_dt_external_id
        
        create_aws_activegate_role-vm
		sleep 180
        create_aws_role_based_access_monitoredaccount
        create_dt_aws
        
        ./makedynakube.sh
        setup_workshop_config
        ;;
esac

echo ""
echo "============================================="
echo "Provisioning workshop resources COMPLETE"
echo "End: $(date)"
echo "============================================="
echo ""

create_EKS_Workshop_Cluster_w_utilities() {

# Function to check if a command is installed
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install Helm
if ! command_exists helm; then
  echo "Installing Helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod +x get_helm.sh
  ./get_helm.sh
fi

# Install kubectl
if ! command_exists kubectl; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Install eksctl
if ! command_exists eksctl; then
  echo "Installing eksctl..."
  sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | sudo tar xz -C /usr/local/bin
fi

# Deploy Kubernetes cluster
echo "Deploying Kubernetes cluster..."
eksctl create cluster --with-oidc --ssh-access --version=1.26 --managed --name workshop-SH-test --tags "Purpose=dynatrace-modernization-workshop" --ssh-public-key ee-default-keypair

echo "Kubernetes cluster deployment complete!"
}

create_EKS_Workshop_Cluster_w_utilities