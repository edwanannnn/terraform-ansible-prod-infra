variable "aws_region" {
  description = "AWS region to deploy infrastructure into."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Short lowercase project identifier used in resource naming."
  type        = string
  default     = "prod-web-stack"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment label (e.g. prod, staging)."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the application/database host."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size_gb" {
  description = "Encrypted gp3 root EBS volume size in GB."
  type        = number
  default     = 30
}

variable "ssh_public_key_path" {
  description = "Local path to the SSH public key uploaded to the EC2 key pair."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Local path to the SSH private key written into the generated Ansible inventory."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "allowed_ssh_cidr" {
  description = "Restricted CIDR allowed to reach SSH (never leave 0.0.0.0/0 in production)."
  type        = string

  validation {
    condition     = var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Restrict allowed_ssh_cidr to your static IP or VPN CIDR instead of 0.0.0.0/0."
  }
}

variable "backup_retention_days" {
  description = "Number of days before S3 PostgreSQL backups expire automatically."
  type        = number
  default     = 90
}
