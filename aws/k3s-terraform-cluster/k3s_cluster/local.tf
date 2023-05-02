locals {
  k3s_tls_san_public     = var.cluster_config.create_extlb && var.cluster_config.expose_kubeapi ? aws_lb.external_lb[0].dns_name : ""
  kubeconfig_secret_name = "${var.common_prefix}-kubeconfig-${var.global_config.name}-${var.global_config.environment}-${var.global_config.organization}-${var.global_config.environment}-v2"
  instance_type          = var.global_config.environment == "mgmt" ? var.cluster_config.cluster_instance_type : (var.global_config.environment != "mgmt" ? var.default_instance_type : var.default_instance_type)
  instance_types = {
    asg_instance_type_1 = var.global_config.environment == "mgmt" ? var.cluster_config.cluster_instance_type : (var.global_config.environment != "mgmt" ? var.default_instance_type : var.default_instance_type)
    asg_instance_type_2 = "t3a.medium"
    asg_instance_type_3 = "c5a.large"
    asg_instance_type_4 = "c6a.large"
    asg_instance_type_5 = "t3.large"
  }
  global_tags = {
    environment      = "${var.global_config.environment}"
    provisioner      = "terraform"
    k3s_cluster_name = "k3s-cluster"
    application      = "k3s"
  }
}