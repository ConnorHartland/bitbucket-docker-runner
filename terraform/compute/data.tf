# Cross-stack reference to infrastructure outputs
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "bitbucket-runner-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

# Data source to get the latest AMI built by Image Builder
# Only queried when deploy_ec2_instance = true
# Uses tag-based lookup (not direct state dependency on image-builder stack)
data "aws_ami" "bitbucket_runner" {
  count = var.deploy_ec2_instance ? 1 : 0

  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["bitbucket-runner-*"]
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
