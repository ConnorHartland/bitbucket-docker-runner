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

# CrowdStrike Falcon
variable "enable_crowdstrike" {
  description = "Enable CrowdStrike Falcon sensor installation"
  type        = bool
  default     = false
}

variable "falcon_sensor_bucket" {
  description = "S3 bucket containing Falcon sensor RPM"
  type        = string
  default     = ""
}

variable "falcon_sensor_key" {
  description = "S3 key (path) to Falcon sensor RPM"
  type        = string
  default     = ""
}

# Wazuh
variable "enable_wazuh" {
  description = "Enable Wazuh agent installation"
  type        = bool
  default     = false
}

# Nessus
variable "enable_nessus" {
  description = "Enable Nessus agent installation"
  type        = bool
  default     = false
}

variable "nessus_agent_bucket" {
  description = "S3 bucket containing Nessus agent RPM"
  type        = string
  default     = ""
}

variable "nessus_agent_key" {
  description = "S3 key (path) to Nessus agent RPM"
  type        = string
  default     = ""
}

# New Relic
variable "enable_newrelic" {
  description = "Enable New Relic infrastructure agent installation"
  type        = bool
  default     = false
}

# Node.js
variable "enable_nodejs" {
  description = "Enable Node.js installation"
  type        = bool
  default     = false
}

# Firewall (nftables)
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
