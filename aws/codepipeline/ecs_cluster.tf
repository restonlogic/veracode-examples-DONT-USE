resource "aws_ecs_cluster" "codepipeline-deploy" {
  name = "codepipeline-deploy"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.codepipeline-deploy.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}