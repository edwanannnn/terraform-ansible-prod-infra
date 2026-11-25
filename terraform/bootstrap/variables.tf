variable "aws_region" {
  description = "AWS region for the Terraform remote state bucket and lock table."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Short lowercase project identifier."
  type        = string
  default     = "prod-web-stack"
}
