# Environment configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID to deploy resources into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy resources into"
  type        = string
}

# Instance configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
  default     = "kijanikiosk-key"
}

# SSH security
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into servers"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # CHANGE THIS to your IP in production
}
