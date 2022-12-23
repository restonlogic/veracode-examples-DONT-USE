#!/bin/bash
set -e

action=$1

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

echo "Deploying networking"
rm -rf .terraform
rm -rf .terraform.lock.hcl
terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="region=$REGION" \
    -backend-config="key=${NAME}-network-services.tfstate"

terraform validate
case $action in
apply)
    echo "Running Terraform Apply Full"
    terraform apply -auto-approve -compact-warnings \
        -var-file=../manifest.json
    ;;
destroy)
    echo "Running Terraform Destroy"
    terraform destroy -auto-approve -compact-warnings \
        -var-file=../manifest.json
    ;;
plan)
    echo "Running Terraform Plan"
    terraform plan -compact-warnings \
        -var-file=../manifest.json
    ;;
esac