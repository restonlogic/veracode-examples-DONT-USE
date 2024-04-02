module "storage_class" {
  source = "../modules/efs-storageclass"

  global_config = var.global_config
}

module "cluster_autoscaler" {
  source = "../modules/cluster-autoscaler"

  depends_on = [module.storage_class]
}

module "skooner" {
  source = "../modules/skooner"

  depends_on = [module.cluster_autoscaler]
}

# module "jenkins" {
#   source = "../modules/jenkins"

#   global_config = var.global_config
#   git_config    = var.git_config

#   depends_on = [module.cluster_autoscaler]
# }
