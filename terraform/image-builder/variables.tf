variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Shared Services VPC
variable "vpc_name" {
  description = "Name tag of the shared services VPC to use"
  type        = string
  default     = "ffc-use1-shared-services-shared-01"
}

# S3 bucket for security agent RPMs
variable "golden_image_bucket" {
  description = "S3 bucket containing security agent RPMs (falcon-sensor.rpm, wazuh-agent.rpm, nessus_agent.rpm)"
  type        = string
  default     = "goldenimage-poc"
}

# Firewall configuration (required - firewall is always included)
variable "firewall_config_bucket" {
  description = "S3 bucket containing nftables configuration"
  type        = string
}

variable "firewall_config_key" {
  description = "S3 key (path) to nftables configuration file"
  type        = string
}

# Optional: Docker
variable "enable_docker" {
  description = "Enable Docker and docker-compose installation"
  type        = bool
  default     = false
}

# Optional: Node.js
variable "enable_nodejs" {
  description = "Enable Node.js installation"
  type        = bool
  default     = false
}

# Optional: New Relic
variable "enable_newrelic" {
  description = "Enable New Relic infrastructure agent installation"
  type        = bool
  default     = false
}
