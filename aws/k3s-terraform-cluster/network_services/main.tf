data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "${var.global_config.name}-${var.global_config.environment}"
  cidr   = var.global_config.vpc_cidr

  azs = [
    data.aws_availability_zones.azs.names[0],
    data.aws_availability_zones.azs.names[1],
    data.aws_availability_zones.azs.names[2]
  ]

  private_subnets = [
    cidrsubnet(var.global_config.vpc_cidr, 8, 1),
    cidrsubnet(var.global_config.vpc_cidr, 8, 3),
    cidrsubnet(var.global_config.vpc_cidr, 8, 5)
  ]

  public_subnets = [
    cidrsubnet(var.global_config.vpc_cidr, 8, 2),
    cidrsubnet(var.global_config.vpc_cidr, 8, 4),
    cidrsubnet(var.global_config.vpc_cidr, 8, 6)
  ]

  database_subnets = [
    cidrsubnet(var.global_config.vpc_cidr, 8, 101),
    cidrsubnet(var.global_config.vpc_cidr, 8, 102),
    cidrsubnet(var.global_config.vpc_cidr, 8, 103)
  ]

  create_database_subnet_group = true

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "Type"                   = "Public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "Type"                            = "Private"
  }

  database_subnet_tags = {
    Type = "${var.global_config.name} Database Subnet"
  }

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  vpc_tags = {
    Environment = var.global_config.environment
  }
}