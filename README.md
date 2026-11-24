# Production AWS Infrastructure with Terraform & Ansible

Automated, repeatable Infrastructure as Code (IaC) and configuration management pipeline that provisions a hardened AWS production server and configures Nginx TLS + verified PostgreSQL backups to S3.

## Architecture

```
                         ┌──────────────────────────────┐
   Admin IP (CIDR) ──22──▶│   AWS VPC + Security Group   │
   Public Traffic  80/443▶│   EC2 Ubuntu 24.04 (IMDSv2)  │
                         │   + Encrypted gp3 EBS + EIP  │
                         └──────────────┬───────────────┘
                                        │
        ┌───────────────────────────────┼───────────────────────────────┐
        ▼                               ▼                               ▼
┌────────────────┐             ┌─────────────────┐             ┌──────────────────┐
│  Role:         │             │  Role:          │             │  Role:           │
│  security      │             │  nginx_ssl      │             │  postgres_backup │
│                │             │                 │             │                  │
│ • Non-root user│             │ • Rate-limited  │             │ • Daily pg_dump  │
│ • sshd harden  │             │   reverse proxy │             │ • SHA-256 verify │
│ • UFW + Fail2ban             │ • HSTS/headers  │             │ • S3 AES-256     │
│ • Auto-upgrades│             │ • Let's Encrypt │             │   (30d IA/90d)   │
└────────────────┘             └─────────────────┘             └────────┬─────────┘
                                                                        │ IAM Role
                                                                        ▼
                                                               ┌──────────────────┐
                                                               │  Private S3      │
                                                               │  Backup Bucket   │
                                                               └──────────────────┘
```

## Key Security & Reliability Controls

- **Terraform Provisioning (`terraform/`):**
  - Dedicated VPC, public subnet, Internet Gateway, and Security Group rejecting SSH from `0.0.0.0/0` via variable validation.
  - EC2 Ubuntu 24.04 host enforcing **IMDSv2** and **encrypted gp3 EBS** root volume.
  - Least-privilege **IAM Instance Profile** scoped strictly to `s3:ListBucket`, `s3:PutObject`, and `s3:GetObject` on the backup bucket (no static AWS keys stored on the server).
  - Private **S3 backup bucket** with versioning, AES-256 encryption, Public Access Block, and lifecycle rules (30-day Infrequent Access, 90-day expiration).
  - Auto-generates `ansible/inventory.ini` via `templatefile` so zero manual IP copying is needed.
- **Ansible Configuration (`ansible/`):**
  - **`security` role:** Creates non-root `deploy` sudo user, disables root/password SSH login, restricts SSH `MaxAuthTries 3`, configures **UFW** default-deny firewall, enables **Fail2ban**, and turns on `unattended-upgrades`.
  - **`nginx_ssl` role:** Sets up rate-limited Nginx reverse proxy (`15r/s`, burst `30`), security headers, `/healthz` endpoint, and automated **Certbot Let's Encrypt** HTTPS redirect.
  - **`postgres_backup` role:** Schedules daily `pg_dump -Fc` backups, validates archive integrity (`pg_restore --list`) + SHA-256 checksums before uploading to S3, prunes local files >7 days, and includes `pg_restore_test.sh` to verify backups directly from S3.
- **CI Validation (`.github/workflows/infra-ci.yml`):**
  - Runs `terraform fmt -check`, `terraform validate`, `ansible-lint`, and `ansible-playbook --syntax-check` on every push/PR.

## Quickstart

### 1. Provision AWS Infrastructure (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your trusted SSH CIDR and key paths

terraform init
terraform plan
terraform apply
```

Terraform automatically writes `ansible/inventory.ini` with the Elastic IP and S3 bucket name.

### 2. Configure & Harden Host (Ansible)

```bash
cd ../ansible
cp group_vars/all.yml.example group_vars/all.yml
# Edit group_vars/all.yml with your domain_name and certbot_email

ansible-galaxy collection install ansible.posix community.general community.postgresql
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory.ini playbook.yml
```

### 3. Verify Automated Backups & Restore Integrity

On the provisioned server:

```bash
sudo -u postgres /usr/local/bin/pg_backup_s3.sh
sudo -u postgres /usr/local/bin/pg_restore_test.sh
```
