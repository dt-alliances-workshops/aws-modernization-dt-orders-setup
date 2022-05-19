#!/bin/bash

create_dynakube()
{
  # reference: https://www.dynatrace.com/support/help/setup-and-configuration/setup-on-container-platforms/kubernetes/get-started-with-kubernetes-monitoring
  
  DYNAKUBE_TEMPLATE_FILE="dynakube.yaml.template"
  DYNAKUBE_GEN_FILE="../gen/dynakube.yaml"

  # create new file from the template with learner Dynatrace tenant information
  rm -f $DYNAKUBE_GEN_FILE

  DT_API_TOKEN_ENCODED=$(echo -n $DT_API_TOKEN | base64)
  cat $DYNAKUBE_TEMPLATE_FILE | \
    sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN_ENCODED"'~' | \
    sed 's~DT_BASEURL_PLACEHOLDER~'"$DT_BASEURL"'~' | \
    sed 's~CLUSTER_NAME_PLACEHOLDER~'"$CLUSTER_NAME"'~' >> $DYNAKUBE_GEN_FILE

  echo "Saved dynatrace operator secrets file to: $DYNAKUBE_GEN_FILE"
}

CREDS_FILE="../gen/workshop-credentials.json"
if [ -f "$CREDS_FILE" ]
then
    DT_BASEURL=$(cat $CREDS_FILE | jq -r '.DT_BASEURL')
    DT_API_TOKEN=$(cat $CREDS_FILE | jq -r '.DT_API_TOKEN')
    CLUSTER_NAME=$(cat $CREDS_FILE | jq -r '.CLUSTER_NAME')
else
  echo "ABORT: CREDS_FILE: $CREDS_FILE not found"
  exit 1
fi

create_dynakube