#!/bin/bash

TARGET=$1

case "$TARGET" in
    "prod") 
        TARGET_URL=s3://aws-modernize-workshop-cloudformation
        ;;
    "staging") 
        TARGET_URL=s3://aws-modernize-workshop-stg-cloudformation
        ;;
    *)
        echo ""
        echo "-----------------------------------------------------------------------------------"
        echo "ERROR: Missing or invalid TARGET argument"
        echo "Valid values are: prod, staging"
        echo ""
        exit 1
        ;;
esac

echo "==================================================================="
echo "About to publish CloudFormation scripts to: $TARGET"
echo "$TARGET_URL"
echo "==================================================================="
read -p "Proceed? (y/n) : " REPLY;

if [[ $REPLY =~ ^[Yy]$ ]]; then

    echo "-----------------------------"
    echo "Syncing to S3"
    echo "-----------------------------"
    aws s3 sync provision-scripts/cloud-formation/ $TARGET_URL

    echo ""
    echo "-----------------------------"
    echo "Done"
    echo "-----------------------------"
    echo ""

fi
