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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type - t3.xlarge provides 4 vCPU, 16GB RAM for running 5+ runners"
  type        = string
  default     = "t3.xlarge"
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

variable "deploy_ec2_instance" {
  description = "Deploy the EC2 instance (set to true after AMI is built)"
  type        = bool
  default     = false
}
