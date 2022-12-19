data "aws_caller_identity" "current" {}

resource "null_resource" "daemonset" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "/tmp/k3s_kubeconfig"
    }
    command = "kubectl apply -f ${path.module}/cluster-autoscaler-autodiscover.yaml"
  }
}