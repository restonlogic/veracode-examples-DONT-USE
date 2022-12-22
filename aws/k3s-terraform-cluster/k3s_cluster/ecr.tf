locals {
  ecr_repos = toset(var.microservices)
}

resource "aws_secretsmanager_secret" "microservices_secret" {
  for_each                = local.ecr_repos
  recovery_window_in_days = 0
  name                    = "/${var.global_config.name}/${var.global_config.environment}/ecr-repo/${each.key}"
}

resource "aws_secretsmanager_secret_version" "microservices_secret" {
  for_each      = local.ecr_repos
  secret_id     = aws_secretsmanager_secret.microservices_secret[each.key].id
  secret_string = aws_ecr_repository.create-ecr-repos[each.key].repository_url
}

# create one ecr repo per microservice
resource "aws_ecr_repository" "create-ecr-repos" {
  for_each             = local.ecr_repos
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
}