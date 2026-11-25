variable "project_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "root_volume_size_gb" {
  type = number
}

variable "public_subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}
