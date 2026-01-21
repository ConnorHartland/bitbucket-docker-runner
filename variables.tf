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

variable "bitbucket_account_uuid" {
  description = "Workspace UUID from Bitbucket (including curly braces)"
  type        = string
}

variable "bitbucket_runner_uuid" {
  description = "Runner UUID from Bitbucket registration (including curly braces)"
  type        = string
}

variable "runner_labels" {
  description = "Comma-separated runner labels"
  type        = string
  default     = "self.hosted,linux"
}

variable "desired_count" {
  description = "Desired number of runners"
  type        = number
  default     = 5
}

variable "min_count" {
  description = "Minimum number of runners"
  type        = number
  default     = 5
}

variable "max_count" {
  description = "Maximum number of runners"
  type        = number
  default     = 10
}
