output "image_builder_pipeline_arn" {
  description = "ARN of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.bitbucket_runner.arn
}

output "enabled_features" {
  description = "Which optional features are enabled in the AMI"
  value = {
    nodejs   = var.enable_nodejs
    newrelic = var.enable_newrelic
    firewall = var.enable_firewall
  }
}

output "security_agents" {
  description = "Security agents always installed"
  value = {
    crowdstrike = true
    wazuh       = true
    nessus      = true
  }
}

output "base_ami" {
  description = "CIS Level 2 Hardened Amazon Linux 2023 base AMI"
  value = {
    id   = data.aws_ami.cis_al2023_l2.id
    name = data.aws_ami.cis_al2023_l2.name
  }
}
