resource "aws_launch_template" "k3s_server" {
  name_prefix   = "${var.common_prefix}-k3s-server-tpl-${var.global_config.environment}"
  image_id      = var.AMIS[var.global_config.region]
  instance_type = local.instance_type
  user_data     = data.template_cloudinit_config.k3s_server.rendered

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = module.key_pair.key_pair_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_strict.id]
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-k3s-server-tpl-${var.global_config.environment}")
    }
  )

}

resource "aws_launch_template" "k3s_worker" {
  name_prefix   = "${var.common_prefix}-k3s-worker-tpl-${var.global_config.environment}"
  image_id      = var.AMIS[var.global_config.region]
  instance_type = local.instance_type
  user_data     = data.template_cloudinit_config.k3s_worker.rendered

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = module.key_pair.key_pair_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_strict.id]
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-k3s-worker-tpl-${var.global_config.environment}")
    }
  )
}