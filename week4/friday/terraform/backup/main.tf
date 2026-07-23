# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Remote backend configuration using MinIO S3-compatible storage
terraform {
  backend "s3" {
    bucket                      = "kijanikiosk-tfstate"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://localhost:9000"
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_region_validation      = true
    force_path_style            = true
    # Note: MinIO S3 backend does not support state locking
    # For production, use DynamoDB (AWS), GCS built-in locking (GCP), or Consul
  }
}

# Data source for the Ubuntu 22.04 AMI (for cloud path)
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = "kijanikiosk"
    ManagedBy   = "terraform"
  }
}

# Security Group for all servers
resource "aws_security_group" "kijanikiosk" {
  name        = "kijanikiosk-sg-${var.environment}"
  description = "Security group for KijaniKiosk servers"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "kijanikiosk-sg-${var.environment}"
  })
}

# Ingress rules - SSH from specific IPs only
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.kijanikiosk.id
  description       = "SSH from allowed IPs only"
}

# Ingress for API server on port 8080
resource "aws_security_group_rule" "api_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kijanikiosk.id
  description       = "API access on port 8080"
}

# Ingress for payments server on port 8081
resource "aws_security_group_rule" "payments_ingress" {
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kijanikiosk.id
  description       = "Payments access on port 8081"
}

# Ingress for logs server on port 9000
resource "aws_security_group_rule" "logs_ingress" {
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kijanikiosk.id
  description       = "Logs access on port 9000"
}

# Egress all outbound
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kijanikiosk.id
  description       = "Allow all outbound"
}

# Module calls for each server
module "api_server" {
  source = "./modules/app_server"
  
  server_name          = "api"
  ami_id               = data.aws_ami.ubuntu_22_04.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_group_ids   = [aws_security_group.kijanikiosk.id]
  key_name             = var.key_name
  environment          = var.environment
  
  depends_on = [aws_security_group.kijanikiosk]
}

module "payments_server" {
  source = "./modules/app_server"
  
  server_name          = "payments"
  ami_id               = data.aws_ami.ubuntu_22_04.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_group_ids   = [aws_security_group.kijanikiosk.id]
  key_name             = var.key_name
  environment          = var.environment
  
  depends_on = [aws_security_group.kijanikiosk]
}

module "logs_server" {
  source = "./modules/app_server"
  
  server_name          = "logs"
  ami_id               = data.aws_ami.ubuntu_22_04.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_group_ids   = [aws_security_group.kijanikiosk.id]
  key_name             = var.key_name
  environment          = var.environment
  
  depends_on = [aws_security_group.kijanikiosk]
}
