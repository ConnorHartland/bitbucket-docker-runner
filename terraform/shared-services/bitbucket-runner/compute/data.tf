# Cross-stack reference to image-builder outputs (for KMS key)
data "terraform_remote_state" "image_builder" {
  backend = "s3"
  config = {
    bucket = "bitbucket-runner-terraform-state"
    key    = "image-builder/terraform.tfstate"
    region = "us-east-1"
  }
}

# Shared Services VPC lookup
data "aws_vpc" "shared_services" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Private subnets lookup (Name tag contains 'private')
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_services.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*", "*Private*"]
  }
}

# Data source to get the latest AMI built by Image Builder
# Only queried when deploy_ec2_instance = true
# Uses tag-based lookup (not direct state dependency on image-builder stack)
data "aws_ami" "golden_image" {
  count = var.deploy_ec2_instance ? 1 : 0

  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["golden-image-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:CreatedBy"
    values = ["EC2ImageBuilder"]
  }
}
