module "cluster_autoscaler" {
  source = "../modules/cluster-autoscaler"
}

module "jenkins" {
  source = "../modules/jenkins"

  global_config  = var.global_config
  git_config     = var.git_config

  depends_on = [module.cluster_autoscaler]
}