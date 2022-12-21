#/bin/bash

set -e

#manifest=$1

# Option defaults
OPT="value"

# getopts string
# This string needs to be updated with the single character options (e.g. -f)
opts="a:n:e:o:u:t:ga:go:gr:gb:cea"

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
    -u, --git_user; provide a Github username
    -t, --git_token; provide a Github token
    -ga,--git_address; provide a Github Address (github.com)
    -go,--git_org; provide a Git Org
    -gr,--git_repo; provide a Git Repo
    -gb,--git_branch; provide a Git Branch 
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
            -u | --git_user)
                git_user=$2
                shift
                ;;
            -t | --git_token)
                git_token=$2
                shift
                ;;
            -ga | --git_address)
                git_address=$2
                shift
                ;;
            -go | --git_org)
                git_org=$2
                shift
                ;;
            -gr | --git_repo)
                git_repo=$2
                shift
                ;;
            -gb | --git_branch)
                git_branch=$2
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

if [ -z $action ] || [ -z $name ] || [ -z $environment ] || [ -z $organization ] || [ -z $git_token ] || [ -z $git_user ] || [[ -z $git_address ]] || [[ -z $git_org ]] || [[ -z $git_repo ]] || [[ -z $git_branch ]] || [ -z $certmanager_email_address ]; then
    usage
    exit 1
fi

manifest=manifest.json

# Set cluster config config
contents="$(jq --arg name $name '.global_config.name = $name' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

contents="$(jq --arg environment $environment '.global_config.environment = $environment' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

contents="$(jq --arg organization $organization '.global_config.organization = $organization' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

contents="$(jq --arg certmanager_email_address $certmanager_email_address '.cluster_config.certmanager_email_address = $certmanager_email_address' ./$manifest)" && \
echo -E "${contents}" > ./$manifest

# Set git configuration
contents="$(jq --arg git_address $git_address '.git_config.gitops_address = $git_address' ./$manifest)" &&
    echo -E "${contents}" > ./$manifest

contents="$(jq --arg git_org $git_org '.git_config.gitops_org = $git_org' ./$manifest)" &&
    echo -E "${contents}" > ./$manifest

contents="$(jq --arg git_repo $git_repo '.git_config.gitops_repo = $git_repo' ./$manifest)" &&
    echo -E "${contents}" > ./$manifest

contents="$(jq --arg git_branch $git_branch '.git_config.gitops_branch = $git_branch' ./$manifest)" &&
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

    # Create Secrets
    cd ${PWD}/secret_services
    bash ./run.sh $action $git_user $git_token
    cd ..

    # Create Network
    cd ${PWD}/network_services
    bash ./run.sh $action
    cd ..

    # Create K3s Cluster
    cd ${PWD}/k3s_cluster
    bash ./run.sh $action
    cd ..


    echo "sleepig for 2 min, waiting for k3s install to finish and get kubeconfig."

    sleep 4m

    k3s_kubeconfig=/tmp/k3s_kubeconfig
    aws secretsmanager get-secret-value --secret-id k3s-kubeconfig-${NAME}-${ENVIRONMENT}-${ORG}-${ENVIRONMENT}-v2 | jq -r '.SecretString' > $k3s_kubeconfig
    ext_lb_dns=$(aws elbv2 describe-load-balancers --names "k3s-ext-lb-$ENVIRONMENT" | jq -r '.LoadBalancers[].DNSName')
    k3s_ext_lb_dns=$(echo https://${ext_lb_dns}:6443)
    yq -i -e ".clusters[].cluster.server = \"$k3s_ext_lb_dns\"" /tmp/k3s_kubeconfig
    export KUBECONFIG=$k3s_kubeconfig

    echo "Infrastructure has been successfully setup"

    cd ${PWD}/k3s_services
    bash ./run.sh $action
    cd ..

    jenkins_pass=$(aws secretsmanager --region $REGION get-secret-value --secret-id /${NAME}/${ENVIRONMENT}/jenkins-secrets --query SecretString --output text | jq -r '."jenkins-admin-password"')
    skooner_token=$(kubectl get secret -n default skooner-sa-token -o json | jq -r '.data.token' | base64 -d)

    ORANGE='\033[0;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    BBLUE='\033[1;34m'
    NC='\033[0m'

    printf "${BLUE}**********************************************************************${NC}\n"
    printf "${BBLUE}The service endpoints are listed below:${NC}\n"
    echo " "
    printf "${BLUE} Jenkins endpoint: ${NC}\n"
    printf "  ${BBLUE} URL${NC}: http://$ext_lb_dns/jenkins\n"
    printf "  ${BBLUE} Credentials${NC}: admin / $jenkins_pass\n"
    echo " "
    echo " "
    printf "${BLUE} K3s Monitoring Dashboard: ${NC}\n"
    printf "  ${BBLUE} URL${NC}: http://$ext_lb_dns/\n"
    printf "  ${BBLUE} Token${NC}: $skooner_token\n"
    echo " "
    printf "${BLUE}**********************************************************************${NC}\n"
    
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

    # Destroy Secrets
    cd ${PWD}/secret_services
    bash ./run.sh $action $git_user $git_token
    cd ..
    
fi