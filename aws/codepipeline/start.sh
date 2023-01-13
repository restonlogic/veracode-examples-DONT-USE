#!/bin/bash

terraform init

terraform "$1" --auto-approve \
-var org="$2" \
-var env="$3" \
-var github-repo="$4" \
-var codestar-connection-arn="$5"