output "bucket_name" {
  value = aws_s3_bucket.pg_backups.bucket
}

output "iam_role_arn" {
  value = aws_iam_role.server_backup.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.server_backup.name
}
