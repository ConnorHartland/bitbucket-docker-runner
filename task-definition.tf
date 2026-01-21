resource "aws_ecs_task_definition" "runner" {
  family                   = "bitbucket-runner"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "bitbucket-runner"
      image     = "docker-public.packages.atlassian.com/sox/atlassian/bitbucket-pipelines-runner:1"
      essential = true

      environment = [
        {
          name  = "ACCOUNT_UUID"
          value = var.bitbucket_account_uuid
        },
        {
          name  = "RUNNER_UUID"
          value = var.bitbucket_runner_uuid
        },
        {
          name  = "WORKING_DIRECTORY"
          value = "/tmp"
        }
      ]

      secrets = [
        {
          name      = "OAUTH_CLIENT_ID"
          valueFrom = "${aws_secretsmanager_secret.bitbucket_oauth.arn}:client_id::"
        },
        {
          name      = "OAUTH_CLIENT_SECRET"
          valueFrom = "${aws_secretsmanager_secret.bitbucket_oauth.arn}:client_secret::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "runner"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "exit 0"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "bitbucket-runner-task"
    Environment = var.environment
  }
}
