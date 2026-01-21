# Security group for EC2 instance running Bitbucket runners
resource "aws_security_group" "ec2_instance" {
  name        = "bitbucket-runners-ec2-instance-sg"
  description = "Security group for Bitbucket runner EC2 instance"
  vpc_id      = aws_vpc.main.id

  # All egress traffic (Docker Hub, package repos, Bitbucket API, AWS services)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No ingress rules - instance runs in private subnet with no inbound access
  # Add SSH ingress from bastion if needed

  tags = {
    Name        = "bitbucket-runners-ec2-instance-sg"
    Environment = var.environment
  }
}
