module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  allowed_ssh_cidr   = var.allowed_ssh_cidr
}

module "backup_storage" {
  source = "./modules/backup_storage"

  project_name          = var.project_name
  backup_retention_days = var.backup_retention_days
}

module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  instance_type             = var.instance_type
  root_volume_size_gb       = var.root_volume_size_gb
  public_subnet_id          = module.network.public_subnet_id
  security_group_id         = module.network.security_group_id
  iam_instance_profile_name = module.backup_storage.instance_profile_name
  ssh_public_key_path       = var.ssh_public_key_path
}

# Auto-generate Ansible inventory from Terraform module outputs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    server_ip            = module.compute.public_ip
    ssh_private_key_path = var.ssh_private_key_path
    backup_s3_bucket     = module.backup_storage.bucket_name
    aws_region           = var.aws_region
  })
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
}
