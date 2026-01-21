# Cross-stack reference to infrastructure outputs
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "bitbucket-runner-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

# Get latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
