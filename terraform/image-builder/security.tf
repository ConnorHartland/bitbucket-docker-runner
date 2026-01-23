# Security group for Image Builder instances
resource "aws_security_group" "image_builder" {
  name        = "golden-image-builder-sg"
  description = "Security group for EC2 Image Builder instances"
  vpc_id      = data.aws_vpc.shared_services.id

  # HTTPS - S3 access for security agent RPMs, SSM, AWS APIs
  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - Package downloads (yum/dnf repos)
  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS - VPC resolver
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

  # No ingress rules - build instances don't need inbound access

  tags = {
    Name        = "golden-image-builder-sg"
    Environment = var.environment
  }
}
