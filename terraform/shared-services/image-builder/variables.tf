variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "image_name" {
  description = "Feature name for AMI (e.g., node22, docker)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# VPC Configuration
variable "vpc_id" {
  description = "VPC ID where Image Builder will run"
  type        = string
}

# S3 bucket for golden image assets
# Expected structure:
#   al2023/rpm/     - Security agent RPMs (falcon-sensor.rpm, wazuh-agent.rpm, nessus_agent.rpm)
#   al2023/scripts/ - Scripts and configs (nftables.conf, UpdateNFTables.sh)
variable "golden_image_bucket" {
  description = "S3 bucket containing golden image assets (RPMs and scripts)"
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
