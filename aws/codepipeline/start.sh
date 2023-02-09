#!/bin/bash

action=$1
git_token=$2
veracode_api_id=$3
veracode_api_key=$4

ACCOUNTID=$(aws sts get-caller-identity | jq -r '.Account')
NAME=$(jq '.global_config.name' -r ./manifest.json)
ENVIRONMENT=$(jq '.global_config.environment' -r ./manifest.json)
REGION=$(jq '.global_config.region' -r ./manifest.json)
ORG=$(jq '.global_config.organization' -r ./manifest.json)

# Color assignments for output
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
NC='\033[0m'

aws configure set default.region $REGION

BUCKET_NAME="tf-state-${NAME}-${ENVIRONMENT}-${ORG}-${ACCOUNTID}"

# Disable exitting on error temporarily for ubuntu users. Below command checks to see if bucket exists.
set +e
rc=$(aws s3 ls s3://${BUCKET_NAME} >/dev/null 2>&1)
set -e
if [ -z $rc ]; then
    # Create bucket if not exist
    aws s3 mb s3://$BUCKET_NAME --region $REGION
else
    printf "${GREEN}Terraform state bucket exists.skipping${NC}\n"
fi

# Saving bucket name for future use
aws ssm put-parameter --name /tf/${NAME}/${ENVIRONMENT}/tfBucketName --overwrite --type String --value $BUCKET_NAME --region $REGION >/dev/null

terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="region=$REGION" \
    -backend-config="key=${NAME}-${ENVIRONMENT}-code-pipeline.tfstate"

printf "${BBLUE}Running terraform $action on Codepipeline${NC}\n"

case $action in
apply)
    terraform apply -auto-approve -compact-warnings \
        -var-file=./manifest.json \
        -var git_token=$git_token \
        -var veracode_api_id=$veracode_api_id \
        -var veracode_api_key=$veracode_api_key
    ;;
destroy)
    terraform destroy -auto-approve -compact-warnings \
        -var-file=./manifest.json \
        -var git_token=$git_token \
        -var veracode_api_id=$veracode_api_id \
        -var veracode_api_key=$veracode_api_key
    ;;
plan)
    terraform plan -compact-warnings \
        -var-file=./manifest.json \
        -var git_token=$git_token \
        -var veracode_api_id=$veracode_api_id \
        -var veracode_api_key=$veracode_api_key
    ;;
esac