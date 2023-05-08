#!/bin/bash
set -e

action=$1
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
NC='\033[0m'

NAME=$(jq '.global_config.name' -r ../manifest.json)
ENVIRONMENT=$(jq '.global_config.environment' -r ../manifest.json)
REGION=$(jq '.global_config.region' -r ../manifest.json)
BUCKET_NAME=$(aws ssm get-parameter --name "/tf/${NAME}/${ENVIRONMENT}/tfBucketName" --region $REGION | jq -r '.Parameter.Value')

if [ -z $action ]; then
    echo "$0 <action>"
    exit 1
fi

if [ -z $NAME ]; then
    echo "$1 <name>"
    exit 1
fi

if [ -z $REGION ]; then
    echo "Terraform region not set or found."
    exit 1
fi

if [ -z $BUCKET_NAME ]; then
    echo "Terraform bucketname not set or found."
    exit 1
fi

printf "${BBLUE}Running terraform $action on k3s_cluster${NC}\n"
rm -rf .terraform
rm -rf .terraform.lock.hcl
terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="region=$REGION" \
    -backend-config="key=${NAME}-${ENVIRONMENT}-lambda.tfstate"

terraform validate
case $action in
apply)
    terraform apply -auto-approve -compact-warnings \
        -var-file=../manifest.json
    ;;
destroy)
    terraform destroy -auto-approve -compact-warnings \
        -var-file=../manifest.json
    ;;
plan)
    terraform plan -compact-warnings \
        -var-file=../manifest.json
    ;;
esac