resource "aws_ecs_service" "runner" {
  name             = "bitbucket-runner-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.runner.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "bitbucket-runner-service"
    Environment = var.environment
  }
}

# Auto-scaling target
resource "aws_appautoscaling_target" "runner" {
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.runner.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto-scaling policy - Target tracking on CPU utilization
resource "aws_appautoscaling_policy" "runner_cpu" {
  name               = "bitbucket-runner-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.runner.resource_id
  scalable_dimension = aws_appautoscaling_target.runner.scalable_dimension
  service_namespace  = aws_appautoscaling_target.runner.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
