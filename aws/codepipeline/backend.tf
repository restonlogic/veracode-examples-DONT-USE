terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }
  }
}

provider "aws" {
  region = var.global_config.region
  default_tags {
    tags = {
      environment  = var.global_config.environment
      name         = var.global_config.name
      organization = var.global_config.organization
      created_by   = "Terraform"
    }
  }
}