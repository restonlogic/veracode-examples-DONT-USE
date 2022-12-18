#/bin/bash

set -e

#manifest=$1

# Option defaults
OPT="value"

# getopts string
# This string needs to be updated with the single character options (e.g. -f)
opts="a:n:e:o:cea"

# Gets the command name without path
cmd() { echo $(basename $0); }

# Help command output
usage() {
    echo "\
    $(cmd) [OPTION...]
    -a, --action; action for terraform to use.
    -n, --name; name to use for deployment, can be veracode.
    -e, --environment; environment being deployed, can be poc.
    -o, --organization; name of the organization.
    -cea, --certmanager-email-address; certificate manager email address to use.
    " | column -t -s ";"
}

# Error message
error() {
    echo "$(cmd): invalid option -- '$1'"
    exit 1
}

# There's two passes here. The first pass handles the long options and
# any short option that is already in canonical form. The second pass
# uses `getopt` to canonicalize any remaining short options and handle
# them

for pass in 1 2; do
    while [ -n "$1" ]; do
        case $1 in
        --)
            shift
            break
            ;;
        -*) case $1 in
            -a | --action)
                action=$2
                shift
                ;;
            -n | --name)
                name=$2
                shift
                ;;
            -e | --environment)
                environment=$2
                shift
                ;;
            -o | --organization)
                organization=$2
                shift
                ;;
            -cea | --certmanager-email-address)
                certmanager_email_address=$2
                shift
                ;;
            -v | --verbose) VERBOSE=$(($VERBOSE + 1)) ;;
            --*) error $1 ;;
            -*) if [ $pass -eq 1 ]; then
                ARGS="$ARGS $1"
            else error $1; fi ;;
            esac ;;
        *) if [ $pass -eq 1 ]; then
            ARGS="$ARGS $1"
        else error $1; fi ;;
        esac
        shift
    done

    if [ $pass -eq 1 ]; then
        ARGS=$(getopt $opts $ARGS)
        if [ $? != 0 ]; then
            usage
            exit 2
        fi
        set -- $ARGS
    fi
done

# Handle positional arguments
if [ -n "$*" ]; then
    echo "$(cmd): Extra arguments -- $*"
    echo "Try '$(cmd) -h' for more information."
    exit 1
fi

if [ -z $action ] || [ -z $name ] || [ -z $environment ] || [ -z $organization ] || [ -z $certmanager_email_address ]; then
    usage
    exit 1
fi

manifest=manifest.json

# Set manifest config
contents="$(jq --arg name $name '.global_config.name = $name' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

contents="$(jq --arg environment $environment '.global_config.environment = $environment' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

contents="$(jq --arg organization $organization '.global_config.organization = $organization' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

contents="$(jq --arg certmanager_email_address $certmanager_email_address '.cluster_config.certmanager_email_address = $certmanager_email_address' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

echo "starting starting installation of base infrastructure"

ACCOUNTID=$(aws sts get-caller-identity | jq -r '.Account')
NAME=$(jq '.global_config.name' -r ./manifest.json)
ENVIRONMENT=$(jq '.global_config.environment' -r ./manifest.json)
REGION=$(jq '.global_config.region' -r ./manifest.json)
ORG=$(jq '.global_config.organization' -r ./manifest.json)

aws configure set default.region $REGION

BUCKET_NAME="tf-state-${NAME}-${ENVIRONMENT}-${ORG}-${ACCOUNTID}"
echo "CREATING TERRAFORM STATE BACKEND BUCKET NAME: ${BUCKET_NAME}"
echo "USIING TERRAFORM BACKEND REGION: ${REGION}"

# Disable exitting on error temporarily for ubuntu users. Below command checks to see if bucket exists.
set +e
rc=$(aws s3 ls s3://${BUCKET_NAME} >/dev/null 2>&1)
set -e
if [ -z $rc ]; then
    # Create bucket if not exist
    aws s3 mb s3://$BUCKET_NAME --region $REGION
else
    echo "Terraform state bucket exists..skipping"
fi

# Saving bucket name for future use
aws ssm put-parameter --name /tf/${NAME}/${ENVIRONMENT}/tfBucketName --overwrite --type String --value $BUCKET_NAME --region $REGION >/dev/null

if [ $action = "apply" ]; then

    # Create Network
    cd ${PWD}/network_services
    bash ./run.sh $action
    cd ..

    Create K3s Cluster
    cd ${PWD}/k3s_cluster
    bash ./run.sh $action
    cd ..


    echo "sleepig for 2 min, waiting for k3s kubeconfig."

    sleep 2m

    k3s_kubeconfig=/tmp/k3s_kubeconfig
    aws secretsmanager get-secret-value --secret-id k3s-kubeconfig-${NAME}-${ENVIRONMENT}-${ORG}-${ENVIRONMENT}-v2 | jq -r '.SecretString' > $k3s_kubeconfig
    ext_lb_dns=$(aws elbv2 describe-load-balancers --names "k3s-ext-lb-$ENVIRONMENT" | jq -r '.LoadBalancers[].DNSName')
    ext_lb_dns=$(echo https://${ext_lb_dns}:6443)
    yq -i -e ".clusters[].cluster.server = \"$ext_lb_dns\"" /tmp/k3s_kubeconfig
    export KUBECONFIG=$k3s_kubeconfig

    echo "Infrastructure has been successfully setup"

    cd ${PWD}/k3s_services
    bash ./run.sh $action
    cd ..
fi

if [ $action = "destroy" ]; then

    # Destroy K3s Cluster
    cd ${PWD}/k3s_cluster
    bash ./run.sh $action
    cd ..

    # Destroy Network
    cd ${PWD}/network_services
    bash ./run.sh $action
    cd ..
    
fi

ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'