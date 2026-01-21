resource "aws_ecs_cluster" "main" {
  name = "bitbucket-runners-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "bitbucket-runners-cluster"
    Environment = var.environment
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    weight            = 4
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/bitbucket-runners"
  retention_in_days = 30

  tags = {
    Name        = "bitbucket-runners-logs"
    Environment = var.environment
  }
}
