resource "null_resource" "skooner" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "/tmp/k3s_kubeconfig"
    }
    command = <<EOT
        kubectl apply -f https://raw.githubusercontent.com/skooner-k8s/skooner/master/kubernetes-skooner.yaml &&
        kubectl create serviceaccount skooner-sa &&
        kubectl apply -f ${path.module}/templates/token.yaml &&
        kubectl apply -f ${path.module}/templates/ingress.yaml
    EOT
  }
}