output "image_builder_pipeline_arn" {
  description = "ARN of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.bitbucket_runner.arn
}

output "enabled_features" {
  description = "Which optional features are enabled in the AMI"
  value = {
    crowdstrike = var.enable_crowdstrike
    wazuh       = var.enable_wazuh
    nessus      = var.enable_nessus
    newrelic    = var.enable_newrelic
    nodejs      = var.enable_nodejs
    firewall    = var.enable_firewall
  }
}
