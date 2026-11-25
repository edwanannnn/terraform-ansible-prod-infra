# Cost-Optimized Single-Node AWS Production Stack (Terraform + Ansible)

Modular Infrastructure as Code (IaC) and Ansible automation for teams and early-stage production workloads that want **real AWS security, remote state management, TLS termination, and verified S3 database backups** without over-engineering or paying for an idle Kubernetes/multi-AZ cluster.

## Architecture

```
                         ┌──────────────────────────────┐
   Admin IP (CIDR) ──22──▶│  Module: network             │
   Public Traffic  80/443▶│  VPC + Subnet + IGW + SG     │
                         └──────────────┬───────────────┘
                                        │
                         ┌──────────────▼───────────────┐
                         │  Module: compute             │
                         │  EC2 Ubuntu 24.04 (IMDSv2)   │
                         │  + Encrypted gp3 EBS + EIP   │
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
  Remote State (bootstrap/):                                   ┌──────────────────┐
  S3 State Bucket + DynamoDB Lock                              │  Module:         │
                                                               │  backup_storage  │
                                                               └──────────────────┘
```

## Design Decisions & Trade-offs

- **Remote State + Locking (`terraform/bootstrap/`):** Separates bootstrap state storage (versioned, encrypted S3 bucket + DynamoDB `LockID` table) from workload infrastructure so state never sits untracked on a developer laptop.
- **Modular Terraform (`terraform/modules/`):** Splits `network`, `backup_storage`, and `compute` cleanly so modules stay readable and reusable across environments.
- **Least-Privilege IAM & IMDSv2:** EC2 uses an instance profile scoped strictly to `s3:ListBucket`, `s3:PutObject`, and `s3:GetObject` on the backup bucket—zero static AWS keys on disk—with IMDSv2 enforced (`http_tokens = "required"`).
- **Verified Backups, Not "Blind Cron":** `pg_backup_s3.sh` validates archive integrity with `pg_restore --list` and records a SHA-256 checksum before uploading, while `pg_restore_test.sh` downloads the latest S3 artifact and checks both integrity and checksum.
- **Pragmatic Single-Node Footprint:** Uses a single EC2 host + S3 off-site backups rather than RDS Multi-AZ or EKS to keep baseline monthly AWS spend low; the Ansible roles remain decoupled if PostgreSQL is later moved to RDS.

## Quickstart

### 1. Bootstrap Remote State Backend (One-Time)

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

Copy the resulting bucket and DynamoDB table outputs into `terraform/backend.hcl`:

```bash
cd ..
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
# Edit backend.hcl and terraform.tfvars (never set allowed_ssh_cidr to 0.0.0.0/0)
```

### 2. Provision Infrastructure (Terraform)

```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Terraform automatically writes `ansible/inventory.ini` with the Elastic IP and S3 bucket name.

### 3. Harden Host, Enable TLS & Configure S3 Backups (Ansible)

```bash
cd ../ansible
cp group_vars/all.yml.example group_vars/all.yml
# Edit group_vars/all.yml with your domain_name and certbot_email

ansible-galaxy collection install ansible.posix community.general community.postgresql
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i inventory.ini playbook.yml
```

### 4. Verify Automated Backups & Restore Integrity

On the provisioned host:

```bash
sudo -u postgres /usr/local/bin/pg_backup_s3.sh
sudo -u postgres /usr/local/bin/pg_restore_test.sh
```
