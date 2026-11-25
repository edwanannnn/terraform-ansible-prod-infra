# Remote state backend using S3 + DynamoDB state locking.
# Initialize with: terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key     = "prod-web-stack/terraform.tfstate"
    encrypt = true
  }
}
