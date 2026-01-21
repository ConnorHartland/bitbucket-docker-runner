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

variable "enable_falcon_sensor" {
  description = "Enable CrowdStrike Falcon sensor installation"
  type        = bool
  default     = false
}

variable "falcon_sensor_s3_bucket" {
  description = "S3 bucket containing Falcon sensor RPM (required if enable_falcon_sensor=true)"
  type        = string
  default     = ""
}

variable "falcon_sensor_s3_key" {
  description = "S3 key (path) to Falcon sensor RPM (required if enable_falcon_sensor=true)"
  type        = string
  default     = ""
}

variable "enable_wazuh_agent" {
  description = "Enable Wazuh agent installation"
  type        = bool
  default     = false
}

variable "enable_nftables" {
  description = "Enable nftables firewall configuration"
  type        = bool
  default     = true
}
