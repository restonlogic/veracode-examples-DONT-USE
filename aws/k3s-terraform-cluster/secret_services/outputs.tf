output "github_secrets_id" {
  value = module.github_secrets[*].secret_id
}

output "jenkins_secrets_id" {
  value = module.jenkins_secrets[*].secret_id
}

output "veracode_secrets_id" {
  value = module.veracode_secrets[*].secret_id
}

output "snow_secrets_id" {
  value = module.snow_secrets[*].secret_id
}