locals {
  k3s_tls_san_public     = var.cluster_config.create_extlb && var.cluster_config.expose_kubeapi ? aws_lb.external_lb[0].dns_name : ""
  kubeconfig_secret_name = "${var.common_prefix}-kubeconfig-${var.global_config.name}-${var.global_config.environment}-${var.global_config.organization}-${var.global_config.environment}-v2"
  global_tags = {
    environment      = "${var.global_config.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k3s-aws-terraform-cluster"
    k3s_cluster_name = "k3s-cluster"
    application      = "k3s"
  }
}