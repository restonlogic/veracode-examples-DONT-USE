module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "${var.common_prefix}-ssh-pubkey-${var.global_config.environment}"
  create_private_key = true
}

module "keypair_secrets" {
  source      = "../modules/secrets-manager-secret"
  secret_name = "/${var.global_config.name}/${var.global_config.environment}/keypair-secrets"
  secret_string = jsonencode({
    private-key-pem     = module.key_pair.private_key_pem
    public-key-pem      = module.key_pair.public_key_pem
    private-key-openssh = module.key_pair.private_key_openssh
    public-key-openssh  = module.key_pair.public_key_openssh
  })
}