#!/bin/bash

echo ""
echo "-----------------------------"
echo "Publishing Cloud Formation"
echo "-----------------------------"

echo "Step 1: Sync to S3"
#aws s3 sync provision-scripts/cloud-formation/ s3://aws-modernize-workshop-cloudformation
aws s3 sync provision-scripts/cloud-formation/ s3://aws-modernize-workshop-stg-cloudformation

echo "-----------------------------"
echo "Done"
echo "-----------------------------"
echo ""