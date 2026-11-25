output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.network.vpc_id
}

output "server_public_ip" {
  description = "Elastic IP assigned to the production server."
  value       = module.compute.public_ip
}

output "backup_s3_bucket" {
  description = "Encrypted S3 bucket storing automated PostgreSQL backups."
  value       = module.backup_storage.bucket_name
}

output "iam_role_arn" {
  description = "Least-privilege IAM role ARN attached to the EC2 instance."
  value       = module.backup_storage.iam_role_arn
}

output "ssh_command" {
  description = "Convenience SSH command using the deployed public IP."
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.compute.public_ip}"
}
