resource "aws_efs_file_system" "k3s_persistent_storage" {
  count          = var.cluster_config.efs_persistent_storage ? 1 : 0
  creation_token = "${var.common_prefix}-efs-persistent-storage-${var.global_config.environment}"
  encrypted      = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-efs-persistent-storage-${var.global_config.environment}")
    }
  )
}

resource "aws_efs_mount_target" "k3s_persistent_storage_mount_target" {
  count           = var.cluster_config.efs_persistent_storage ? length(data.terraform_remote_state.vpc.outputs.private_subnets) : 0
  file_system_id  = aws_efs_file_system.k3s_persistent_storage[0].id
  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnets[count.index]
  security_groups = [aws_security_group.efs_sg[0].id]
}

resource "aws_ssm_parameter" "efs_system_id" {
  name  = "/${var.global_config.name}/${var.global_config.environment}/efs_system_id"
  type  = "String"
  value = aws_efs_file_system.k3s_persistent_storage[0].id
}