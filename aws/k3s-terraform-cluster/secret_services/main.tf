resource "random_string" "random" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

module "github_secrets" {
  source      = "../modules/secrets-manager-secret"
  secret_name = "/${var.global_config.name}/${var.global_config.environment}/secrets"
  secret_string = jsonencode({
    name            = var.global_config.name
    environment     = var.global_config.environment
    git-token       = var.git_pat_token
    git-username    = var.git_pat_user
    gitops-address  = var.git_config.gitops_address
    gitops-org      = var.git_config.gitops_org
    gitops-repo     = var.git_config.gitops_repo
    gitops-branch   = var.git_config.gitops_branch
    gitops-org-url  = "https://${var.git_config.gitops_address}/${var.git_config.gitops_org}"
    gitops-full-url = "https://${var.git_config.gitops_address}/${var.git_config.gitops_org}/${var.git_config.gitops_repo}.git"
  })
}

module "veracode_secrets" {
  source      = "../modules/secrets-manager-secret"
  secret_name = "/${var.global_config.name}/${var.global_config.environment}/veracode-secrets"
  secret_string = jsonencode({
    veracode-api-id        = var.veracode_api_id
    veracode-api-key       = var.veracode_api_key
    veracode-sca-key       = var.veracode_sca_key
  })
}

resource "random_password" "jenkins_admin_password" {
  length  = 16
  special = false
}

module "jenkins_secrets" {
  source      = "../modules/secrets-manager-secret"
  secret_name = "/${var.global_config.name}/${var.global_config.environment}/jenkins-secrets"
  secret_string = jsonencode({
    username               = "admin"
    jenkins-admin-password = random_password.jenkins_admin_password.result
  })
}