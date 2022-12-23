locals {
  file_jenkins_values = "/tmp/jenkins_values.yaml"

  jenkins_values_yaml = templatefile("${path.module}/templates/values.tpl",
    {
      jenkins_admin_password = jsondecode(data.aws_secretsmanager_secret_version.jenkins_secrets.secret_string)["jenkins-admin-password"]
      git_username           = jsondecode(data.aws_secretsmanager_secret_version.github_secrets.secret_string)["git-username"]
      git_access_token       = jsondecode(data.aws_secretsmanager_secret_version.github_secrets.secret_string)["git-token"]
      gitops_org_url         = "https://${var.git_config.gitops_address}/${var.git_config.gitops_org}"
      gitops_full_url        = "https://${var.git_config.gitops_address}/${var.git_config.gitops_org}/${var.git_config.gitops_repo}.git"
      gitops_address         = var.git_config.gitops_address
      gitops_org             = var.git_config.gitops_org
      gitops_repo            = var.git_config.gitops_repo
      gitops_branch          = var.git_config.gitops_branch
    }
  )
}

resource "local_file" "values" {
  content  = local.jenkins_values_yaml
  filename = local.file_jenkins_values
}

resource "null_resource" "deploy" {
  triggers = {
    file_change  = md5(local_file.values.filename)
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "/tmp/k3s_kubeconfig"
    }
    command = <<EOT
        helm repo add jenkins https://charts.jenkins.io > /dev/null &&
        helm repo update &&
        helm upgrade --wait --install jenkins jenkins/jenkins --namespace jenkins --create-namespace --version 4.2.17 -f ${local_file.values.filename} &&
        kubectl create clusterrolebinding jenkins-sa --clusterrole=cluster-admin --serviceaccount=jenkins:jenkins-sa --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }
}