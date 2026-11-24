output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "server_public_ip" {
  description = "Elastic IP assigned to the production server."
  value       = aws_eip.server.public_ip
}

output "backup_s3_bucket" {
  description = "Encrypted S3 bucket storing automated PostgreSQL backups."
  value       = aws_s3_bucket.pg_backups.bucket
}

output "iam_role_arn" {
  description = "Least-privilege IAM role ARN attached to the EC2 instance."
  value       = aws_iam_role.server_backup.arn
}

output "ssh_command" {
  description = "Convenience SSH command using the deployed public IP."
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_eip.server.public_ip}"
}
