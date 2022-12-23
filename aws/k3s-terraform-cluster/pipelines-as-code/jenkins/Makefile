# These values are passed from the deploy pipeline
serviceName:=""
environment:=""
portNumber:=""
imageName:=""
imageTag:=""
nameSpace:=""
pathPrefix:=""
repoFolder:=""

MAKE_ENV += serviceName environment portNumber imageName imageTag nameSpace pathPrefix repoFolder
SHELL_EXPORT := $(foreach v,$(MAKE_ENV),$(v)='$($(v))')
DEPLOY_TEMPLATE_DIR := pipelines-as-code/jenkins/templates

generate-manifests:
	echo "Preparing k8s yaml files for ${serviceName}..."
	@$(SHELL_EXPORT) envsubst < $(DEPLOY_TEMPLATE_DIR)/${serviceName}.yaml > $(repoFolder)/${serviceName}.yaml
	@$(SHELL_EXPORT) envsubst < $(DEPLOY_TEMPLATE_DIR)/ingress.yaml    	   > $(repoFolder)/ingress.yaml