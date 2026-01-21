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

# S3 bucket for security agent RPMs
variable "golden_image_bucket" {
  description = "S3 bucket containing security agent RPMs (falcon-sensor.rpm, wazuh-agent.rpm, nessus_agent.rpm)"
  type        = string
  default     = "goldenimage-poc"
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

# Optional: Firewall (nftables)
variable "enable_firewall" {
  description = "Enable nftables firewall configuration from S3"
  type        = bool
  default     = false
}

variable "firewall_config_bucket" {
  description = "S3 bucket containing nftables configuration"
  type        = string
  default     = ""
}

variable "firewall_config_key" {
  description = "S3 key (path) to nftables configuration file"
  type        = string
  default     = ""
}
