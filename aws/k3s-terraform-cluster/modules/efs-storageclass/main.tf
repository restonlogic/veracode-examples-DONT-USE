data "aws_ssm_parameter" "efs_system_id" {
  name = "/${var.global_config.name}/${var.global_config.environment}/efs_system_id"
}

locals {
  file_sc_values = "/tmp/storageclass.yaml"

  sc_values_yaml = templatefile("${path.module}/storageclass.tpl",
    {
      efs_system_id = data.aws_ssm_parameter.efs_system_id.value
    }
  )
}

resource "local_file" "values" {
  content  = local.sc_values_yaml
  filename = local.file_sc_values
}

resource "null_resource" "storage_class" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "/tmp/k3s_kubeconfig"
    }
    command = "kubectl apply -f ${local_file.values.filename}"
  }
}