resource "aws_security_group" "ecs_tasks" {
  name        = "bitbucket-runners-ecs-tasks-sg"
  description = "Security group for Bitbucket runner ECS tasks"
  vpc_id      = aws_vpc.main.id

  # HTTPS egress for Bitbucket API, ECR, S3, and other AWS services
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP egress for package downloads
  egress {
    description = "HTTP outbound for package downloads"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bitbucket-runners-ecs-tasks-sg"
    Environment = var.environment
  }
}
