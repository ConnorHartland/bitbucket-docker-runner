output "image_builder_pipeline_arn" {
  description = "ARN of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.bitbucket_runner.arn
}

output "enabled_features" {
  description = "Which optional features are enabled in the AMI"
  value = {
    wazuh_agent   = var.enable_wazuh_agent
    falcon_sensor = var.enable_falcon_sensor
    nftables      = var.enable_nftables
  }
}
