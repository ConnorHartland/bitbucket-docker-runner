# VPC lookup for CIDR block
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Private subnets lookup (Name tag contains 'private')
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*", "*Private*"]
  }
}

data "aws_caller_identity" "current" {}

# Get latest CIS Level 2 Hardened Amazon Linux 2023 AMI
# Published by CIS (Center for Internet Security) via AWS Marketplace
data "aws_ami" "cis_al2023_l2" {
  most_recent = true
  owners      = ["679593333241"] # CIS AWS Marketplace owner ID

  filter {
    name   = "name"
    values = ["CIS Amazon Linux 2023 Benchmark - Level 2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
