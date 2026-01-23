output "image_builder_pipeline_arn" {
  description = "ARN of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.golden_image.arn
}

output "enabled_features" {
  description = "Which optional features are enabled in the AMI"
  value = {
    docker   = var.enable_docker
    nodejs   = var.enable_nodejs
    newrelic = var.enable_newrelic
  }
}

output "security_agents" {
  description = "Security agents always installed"
  value = {
    crowdstrike = true
    wazuh       = true
    nessus      = true
    firewall    = true
  }
}

output "base_ami" {
  description = "CIS Level 2 Hardened Amazon Linux 2023 base AMI"
  value = {
    id   = data.aws_ami.cis_al2023_l2.id
    name = data.aws_ami.cis_al2023_l2.name
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = aws_kms_key.golden_image.arn
}

output "kms_key_id" {
  description = "ID of the KMS key for encryption"
  value       = aws_kms_key.golden_image.key_id
}

output "vpc_id" {
  description = "ID of the shared services VPC"
  value       = data.aws_vpc.shared_services.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = data.aws_subnets.private.ids
}
