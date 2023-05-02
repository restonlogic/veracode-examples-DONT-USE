resource "aws_vpc_endpoint" "vpce_secretsmanager" {
  count             = var.global_config.environment == "mgmt" ? 1 : 0
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name      = "com.amazonaws.${var.global_config.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
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

resource "aws_vpc_endpoint" "vpce_lambda" {
  count             = var.global_config.environment == "mgmt" ? 1 : 0
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name      = "com.amazonaws.${var.global_config.region}.lambda"
  vpc_endpoint_type = "Interface"

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids = [
    aws_security_group.internal_vpce_sg.id,
  ]

  private_dns_enabled = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-lambda-vpce-${var.global_config.environment}")
    }
  )
}

resource "aws_vpc_endpoint" "vpce_sts" {
  count             = var.global_config.environment == "mgmt" ? 1 : 0
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name      = "com.amazonaws.${var.global_config.region}.sts"
  vpc_endpoint_type = "Interface"

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids = [
    aws_security_group.internal_vpce_sg.id,
  ]

  private_dns_enabled = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-sts-vpce-${var.global_config.environment}")
    }
  )
}

resource "aws_vpc_endpoint" "vpce_s3" {
  count             = var.global_config.environment == "mgmt" ? 1 : 0
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name      = "com.amazonaws.${var.global_config.region}.s3"
  vpc_endpoint_type = "Interface"

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids = [
    aws_security_group.internal_vpce_sg.id,
    aws_security_group.lambda_sg[count.index].id,
  ]

  private_dns_enabled = false

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-sts-s3-${var.global_config.environment}")
    }
  )
}