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
        kubectl create serviceaccount skooner-sa --dry-run=client -o yaml | kubectl apply -f - &&
        kubectl create clusterrolebinding skooner-sa --clusterrole=cluster-admin --serviceaccount=default:skooner-sa --dry-run=client -o yaml | kubectl apply -f - && 
        kubectl apply -f ${path.module}/templates/token.yaml &&
        kubectl apply -f ${path.module}/templates/ingress.yaml
    EOT
  }
}