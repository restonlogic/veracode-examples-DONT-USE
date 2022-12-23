resource "aws_vpc_endpoint" "vpce_secretsmanager" {
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name      = "com.amazonaws.${var.global_config.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets
  security_group_ids = [
    aws_security_group.internal_vpce_sg.id,
  ]

  private_dns_enabled = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-secretsmanager-vpce-${var.global_config.environment}")
    }
  )
}