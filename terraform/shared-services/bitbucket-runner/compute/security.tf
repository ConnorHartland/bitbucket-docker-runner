# Security group for EC2 instances running Bitbucket runners
resource "aws_security_group" "ec2_instance" {
  name        = "bitbucket-runners-ec2-instance-sg"
  description = "Security group for Bitbucket runner EC2 instance"
  vpc_id      = data.aws_vpc.shared_services.id

  # HTTPS - Bitbucket API, Docker registries, AWS APIs, package repos
  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - Package downloads (some repos still use HTTP)
  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS - VPC resolver only
  egress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.shared_services.cidr_block]
  }

  egress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared_services.cidr_block]
  }

  # Git SSH - For SSH-based git operations
  egress {
    description = "Git SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NTP - Time synchronization
  egress {
    description = "NTP"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No ingress rules - instance runs in private subnet with no inbound access

  tags = {
    Name        = "bitbucket-runners-ec2-instance-sg"
    Environment = var.environment
  }
}
