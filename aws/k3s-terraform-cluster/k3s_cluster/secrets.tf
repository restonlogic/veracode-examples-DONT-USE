resource "aws_secretsmanager_secret" "kubeconfig_secret" {
  name                    = local.kubeconfig_secret_name
  recovery_window_in_days = 0
  description             = "Kubeconfig k3s. Cluster name: ${var.global_config.name}-${var.global_config.environment}-${var.global_config.organization}, environment: ${var.global_config.environment}"

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeconfig_secret_name}")
    }
  )
}