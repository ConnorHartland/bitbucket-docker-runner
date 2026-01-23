# Cross-stack reference to infrastructure outputs (VPC, subnets, security group, KMS)
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "bitbucket-runner-terraform-state"
    key    = "shared-services/bitbucket-runner/infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  vpc_id             = data.terraform_remote_state.infrastructure.outputs.vpc_id
  vpc_cidr           = data.terraform_remote_state.infrastructure.outputs.vpc_cidr
  private_subnet_ids = data.terraform_remote_state.infrastructure.outputs.private_subnet_ids
  security_group_id  = data.terraform_remote_state.infrastructure.outputs.security_group_id
  kms_key_arn        = data.terraform_remote_state.infrastructure.outputs.kms_key_arn
  kms_key_id         = data.terraform_remote_state.infrastructure.outputs.kms_key_id
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
