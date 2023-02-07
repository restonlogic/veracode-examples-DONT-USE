#!/bin/bash

terraform init

terraform "$1" --auto-approve \
-var org="$2" \
-var env="$3" \
-var github-repo="$4" \
-var connection-arn="$5"

if [ "$1" = "destroy" ]; then
    aws iam delete-role --role-name "$6"
    aws lambda delete-function --function-name "$7"
fi