#!/bin/bash
export aws_PAGER=""
export AWS_PAGER=""

#get the availability zone of the region
AZ=$(aws ec2 describe-availability-zones --query "AvailabilityZones[0].ZoneName" --output text)

echo "The availability zone is: $AZ"

createDB() 
{
     aws rds create-db-instance \
         --region ${AZ::-1} \
         --db-instance-identifier catalog-mysql-instance \
         --db-instance-class db.t3.micro \
         --engine mysql \
         --master-username admin \
         --master-user-password Alliances2024 \
         --allocated-storage 20 \
         --no-cli-pager   

        # Wait for the RDS instance to become available
        while true; do
            status=$(aws rds describe-db-instances --db-instance-identifier catalog-mysql-instance --query 'DBInstances[0].DBInstanceStatus' --output text)
            if [[ $status == "available" ]]; then
                break
            else
                echo "Waiting 10 more secs for the catalog to be ready"    
                sleep 10
            fi
        done
                                                                                                                                      
        export RDS_HOST=$(aws rds describe-db-instances --db-instance-identifier catalog-mysql-instance --query 'DBInstances[0].Endpoint.Address' --output text)
        echo "The DB host name is: $RDS_HOST"

        #Retrieve security group associated with the RDS instance
        security_group_id=$(aws rds describe-db-instances \
        --db-instance-identifier catalog-mysql-instance \
        --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
        --output text)

        # Store security group ID in an environment variable
        export RDS_SECURITY_GROUP="$security_group_id"

        # Print the environment variable
        echo "RDS Security Group ID: $RDS_SECURITY_GROUP"

    aws ec2 authorize-security-group-ingress \
        --group-id $RDS_SECURITY_GROUP \
        --protocol all \
        --cidr 0.0.0.0/0

        # Connect to the RDS instance and execute the SQL script
    mysql -h "$RDS_HOST" -u admin -p"Alliances2024" < create.sql > mysql_log.txt 2>&1

   # create our IAM role that allows lambda to talk to RDS
   aws iam create-role --role-name lambda-function --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
   #add policy to role for CW logs
   aws iam attach-role-policy --role-name lambda-function --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
   #list the policies after they are attached
   aws iam list-attached-role-policies --role-name lambda-function
   
   export createRoleLambda=$(aws iam get-role --role-name lambda-function --query 'Role.Arn' --output text)
   echo "RDS Security Group ID: $createRoleLambda"

   #attach policy to IAM Role
    aws iam attach-role-policy \
        --role-name lambda-function \
        --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess
}

createEV()
{
# Update the path to point to the specific directory where the JSON file is located
CREDENTIALS_FILE="$HOME/aws-modernization-dt-orders-setup/gen/workshop-credentials.json"

# Use jq to extract the values from the JSON file
DT_BASEURL=$(jq -r '.DT_BASEURL' $CREDENTIALS_FILE)
DT_API_TOKEN=$(jq -r '.DT_API_TOKEN' $CREDENTIALS_FILE)
CLUSTER_NAME=$(jq -r '.CLUSTER_NAME' $CREDENTIALS_FILE)
DT_UUID=$(echo "DT_BASEURL: $DT_BASEURL" | grep -oE '[a-f0-9\-]{36}')

# Now you can use these variables in your script
echo "DT_BASEURL: $DT_BASEURL"
echo "DT_API_TOKEN: $DT_API_TOKEN"
echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "UUID: $DT_UUID"

    #set the environment variables
    export DB_NAME="catalog"
    export PASSWORD="Alliances2024"
    export USER_NAME="admin"
    export RDS_INSTANCE_IDENTIFIER="catalog-mysql-instance"
    # Use the AWS CLI to get DB instance details and parse the output for the endpoint address
    export RDS_HOST=$(aws rds describe-db-instances --db-instance-identifier catalog-mysql-instance --query 'DBInstances[0].Endpoint.Address' --output text)
    echo "The DB host name is: $RDS_HOST"
    export createRoleLambda=$(aws iam get-role --role-name lambda-function --query 'Role.Arn' --output text)
     echo "The createRoleLambda name is: $createRoleLambda"

    #Dynatrace EnvVars
    export AWS_LAMBDA_EXEC_WRAPPER="/opt/dynatrace"
    export DT_TENANT="$DT_UUID"
    export DT_CLUSTER_ID="1649838510"
    export DT_CONNECTION_BASE_URL="https://syh360.dynatrace-managed.com"
    export DT_CONNECTION_AUTH_TOKEN="$DT_API_TOKEN"
    export DT_OPEN_TELEMETRY_ENABLE_INTEGRATION="true"
    export Layer_ARN=arn:aws:lambda:us-west-2:725887861453:layer:Dynatrace_OneAgent_1_279_2_20231020-042318_python:1
#    export Layer_ARN="arn:aws:lambda:us-west-2:725887861453:layer:Dynatrace_OneAgent_1_277_3_20231004-104443_python:1"
}   


createLambdafindByNameContains()
{
    # deploy findByNameContains lambda function
    #--environment "Variables={DB_NAME=${DB_NAME},PASSWORD=${PASSWORD},RDS_HOST=${RDS_HOST},USER_NAME=${USER_NAME}}" \
    aws lambda create-function \
        --function-name findByNameContains \
        --runtime python3.9 \
        --zip-file fileb://findByName.zip \
        --handler lambda_function.lambda_handler \
        --role "${createRoleLambda}" \
        --environment "Variables={DB_NAME=${DB_NAME},PASSWORD=${PASSWORD},RDS_HOST=${RDS_HOST},USER_NAME=${USER_NAME},AWS_LAMBDA_EXEC_WRAPPER=${AWS_LAMBDA_EXEC_WRAPPER},DT_TENANT=${DT_TENANT},DT_CLUSTER_ID=${DT_CLUSTER_ID},DT_CONNECTION_BASE_URL=${DT_CONNECTION_BASE_URL},DT_CONNECTION_AUTH_TOKEN="REPLACE-ME-PLEASE",DT_OPEN_TELEMETRY_ENABLE_INTEGRATION=${DT_OPEN_TELEMETRY_ENABLE_INTEGRATION}}" \
        --layers "${Layer_ARN}" \
        --no-paginate \
        --output json
 # Wait a few seconds to ensure the Lambda function has been created before creating the Function URL
 sleep 5
    aws lambda add-permission \
        --function-name findByNameContains \
        --action lambda:InvokeFunctionUrl \
        --principal "*" \
        --function-url-auth-type "NONE" \
        --statement-id url

    aws lambda create-function-url-config \
        --function-name findByNameContains \
        --auth-type NONE

    echo "Function URL for $FUNCTION_NAME created with public access."

}


createLambdaserverlessDBActions()
{
    # deploy findByNameContains lambda function
    #--environment "Variables={DB_NAME=${DB_NAME},PASSWORD=${PASSWORD},RDS_HOST=${RDS_HOST},USER_NAME=${USER_NAME}}" \
    aws lambda create-function \
        --function-name serverlessDBActions \
        --runtime python3.9 \
        --zip-file fileb://serverlessDBActions.zip \
        --handler lambda_function.lambda_handler \
        --role "${createRoleLambda}" \
        --environment "Variables={DB_NAME=${DB_NAME},PASSWORD=${PASSWORD},RDS_HOST=${RDS_HOST},USER_NAME=${USER_NAME},AWS_LAMBDA_EXEC_WRAPPER=${AWS_LAMBDA_EXEC_WRAPPER},DT_TENANT=${DT_TENANT},DT_CLUSTER_ID=${DT_CLUSTER_ID},DT_CONNECTION_BASE_URL=${DT_CONNECTION_BASE_URL},DT_CONNECTION_AUTH_TOKEN="REPLACE-ME-PLEASE",DT_OPEN_TELEMETRY_ENABLE_INTEGRATION=${DT_OPEN_TELEMETRY_ENABLE_INTEGRATION}}" \
        --layers "${Layer_ARN}" \
        --no-paginate \
        --output json
 # Wait a few seconds to ensure the Lambda function has been created before creating the Function URL
 sleep 5
    aws lambda add-permission \
        --function-name serverlessDBActions \
        --action lambda:InvokeFunctionUrl \
        --principal "*" \
        --function-url-auth-type "NONE" \
        --statement-id url

    aws lambda create-function-url-config \
        --function-name serverlessDBActions \
        --auth-type NONE

    echo "Function URL for $FUNCTION_NAME created with public access."

}

updateCatalogManifest()
{

    findByNameContainsURL=$(aws lambda get-function-url-config --function-name findByNameContains --query 'FunctionUrl' --output text)
    serverlessDBActionsURL=$(aws lambda get-function-url-config --function-name serverlessDBActions --query 'FunctionUrl' --output text)
    
    sed -i "s|CHANGEME_FINDBYNAME|$findByNameContainsURL|g" catalog-service-serverless.yml
    sed -i "s|CHANGEME_SERVERLESS_DB_ACTIONS|$serverlessDBActionsURL|g" catalog-service-serverless.yml

}

#main
createDB
createEV
createLambdafindByNameContains
createLambdaserverlessDBActionsURL
updateCatalogManifest