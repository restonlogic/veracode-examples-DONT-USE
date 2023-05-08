data "aws_ssm_parameter" "remote_state_bucket" {
  name            = "/tf/${var.global_config.name}/${var.global_config.environment}/tfBucketName"
  with_decryption = true
}

data "terraform_remote_state" "secrets" {
  backend = "s3"
  config = {
    bucket = data.aws_ssm_parameter.remote_state_bucket.value
    key    = "${var.global_config.name}-${var.global_config.environment}-secrets.tfstate"
    region = var.global_config.region
  }
}

data "aws_secretsmanager_secret_version" "jenkins_secrets" {
  secret_id = data.terraform_remote_state.secrets.outputs.jenkins_secrets_id[0]
}

data "aws_secretsmanager_secret_version" "github_secrets" {
  secret_id = data.terraform_remote_state.secrets.outputs.github_secrets_id[0]
}

data "aws_secretsmanager_secret_version" "snow_secrets" {
  secret_id = data.terraform_remote_state.secrets.outputs.snow_secrets_id[0]
}

data "aws_lb" "lb" {
  name = "k3s-ext-lb-${var.global_config.environment}"
}