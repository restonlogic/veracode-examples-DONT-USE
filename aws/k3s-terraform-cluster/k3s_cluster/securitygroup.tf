resource "aws_security_group" "allow_strict" {
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.common_prefix}-allow-strict-${var.global_config.environment}"
  description = "security group that allows ssh and all egress traffic"

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-allow-strict-${var.global_config.environment}")
    }
  )
}

resource "aws_security_group_rule" "ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "ingress_kubeapi" {
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "ingress_kubeapi_public_subnet" {
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.vpc.outputs.public_subnets_cidr_blocks
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "allow_lb_http_traffic" {
  count             = var.cluster_config.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_http_port
  to_port           = var.extlb_http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "allow_lb_https_traffic" {
  count             = var.cluster_config.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_https_port
  to_port           = var.extlb_https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "allow_lb_kubeapi_traffic" {
  count             = var.cluster_config.create_extlb && var.cluster_config.expose_kubeapi ? 1 : 0
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group" "efs_sg" {
  count       = var.cluster_config.efs_persistent_storage ? 1 : 0
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.common_prefix}-efs-sg-${var.global_config.environment}"
  description = "Allow EFS access from VPC subnets"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-efs-sg-${var.global_config.environment}")
    }
  )
}

resource "aws_security_group" "internal_vpce_sg" {
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.common_prefix}-int-vpce-sg-${var.global_config.environment}"
  description = "Allow all traffic trought vpce"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
  }

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-int-vpce-sg-${var.global_config.environment}")
    }
  )
}

resource "aws_security_group" "lambda_sg" {
  count       = var.global_config.environment == "mgmt" ? 1 : 0
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.global_config.name}-lambda-sg-${var.global_config.environment}"
  description = "Allow lambda function to access"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.vpc.outputs.public_subnets_cidr_blocks
  }

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.global_config.name}-lambda-sg-${var.global_config.environment}")
    }
  )
}