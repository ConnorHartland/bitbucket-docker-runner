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

variable "instance_type" {
  description = "EC2 instance type - t3.xlarge provides 4 vCPU, 16GB RAM for running 5+ runners"
  type        = string
  default     = "t3.xlarge"
}

variable "enable_falcon_sensor" {
  description = "Enable CrowdStrike Falcon sensor registration at boot"
  type        = bool
  default     = false
}

variable "enable_wazuh_agent" {
  description = "Enable Wazuh agent registration at boot"
  type        = bool
  default     = false
}

variable "enable_nftables" {
  description = "Enable nftables firewall at boot"
  type        = bool
  default     = true
}

variable "deploy_ec2_instance" {
  description = "Deploy the EC2 instance (set to true after AMI is built)"
  type        = bool
  default     = false
}
