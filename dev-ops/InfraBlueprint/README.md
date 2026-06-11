# Vela Payments Infrastructure as Code

This project provisions a reproducible, secure cloud infrastructure for Vela Payments using Terraform. The infrastructure follows AWS best practices and is designed to be destroyed and recreated with a single command.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet (0.0.0.0/0)                    │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
                      ┌──────────────────────┐
                      │  AWS VPC 10.0.0.0/16 │
                      └──────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
        ┌───────────▼──────────┐  ┌──────────▼──────────┐
        │  Public Subnet AZ-1  │  │  Public Subnet AZ-2 │
        │    10.0.1.0/24       │  │    10.0.2.0/24      │
        ├──────────────────────┤  └─────────────────────┘
        │   Internet Gateway   │
        │                      │
        │  ┌────────────────┐  │
        │  │   EC2 Instance │  │
        │  │   t2.micro     │  │
        │  │  [web-sg]      │  │
        │  └────────────────┘  │
        │          │           │
        │          └───────────┼────────────────┐
        │                      │                │
        └──────────────────────┘                │
                                                │
                        ┌───────────────────────▼──────────┐
                        │   Private Subnet AZ-1            │
                        │   10.0.10.0/24                   │
                        │  ┌──────────────────────────────┐│
                        │  │   RDS PostgreSQL 15         ││
                        │  │   db.t3.micro               ││
                        │  │   [db-sg]                   ││
                        │  │   Not publicly accessible   ││
                        │  └──────────────────────────────┘│
                        └────────────────────────────────────┘
                        
                        ┌──────────────────────────────────┐
                        │   Private Subnet AZ-2            │
                        │   10.0.11.0/24                   │
                        │   (RDS Multi-AZ support)         │
                        └──────────────────────────────────┘

┌────────────────────────────────┐
│   S3 Bucket (Static Assets)     │
│   - Public access blocked       │
│   - EC2 access via IAM role     │
│   - Versioning enabled          │
└────────────────────────────────┘
```

---

## Components

### Networking (Part 1)
- **VPC**: `10.0.0.0/16` CIDR block with custom subnets
- **Public Subnets**: Two subnets (`10.0.1.0/24`, `10.0.2.0/24`) in different AZs for the web tier
- **Private Subnets**: Two subnets (`10.0.10.0/24`, `10.0.11.0/24`) in different AZs for the database
- **Internet Gateway**: Attached to VPC for outbound internet access
- **Route Table**: Routes `0.0.0.0/0` through the IGW for public subnets

### Compute (Part 2)
- **EC2 Instance**: Amazon Linux 2023, `t2.micro` in a public subnet
- **Web Security Group** (`web-sg`):
  - Inbound HTTP (80), HTTPS (443) from anywhere
  - Inbound SSH (22) from your IP only (parameterized)
  - All outbound traffic allowed
- **IAM Role**: EC2 instance role with granular S3 access (GetObject, PutObject) to the assets bucket
- **Instance Profile**: Attached to EC2 for IAM permissions

### Database (Part 3)
- **RDS Instance**: PostgreSQL 15, `db.t3.micro` in private subnets
- **Database Security Group** (`db-sg`): Allows port 5432 only from `web-sg`
- **DB Subnet Group**: Spans two private subnets across AZs
- **Credentials**: Parameterized (never hardcoded)
- **Public Accessibility**: Disabled (database is isolated in private subnets)

### Storage (Part 4)
- **S3 Bucket**: For static assets
- **Public Access Block**: All public access disabled
- **Versioning**: Enabled for disaster recovery
- **Bucket Name**: Parameterized (globally unique)

### Backend State (Part 5)
- **S3 Backend**: Remote state management (configured in `main.tf`)
- **Variables**: All configurable values in `variables.tf`
- **Outputs**: EC2 IP, RDS endpoint, S3 bucket name

---

## Supported Cloud Providers

- `infra/` - AWS Terraform configuration
- `gcp/` - GCP Terraform configuration

## Using AWS

Follow the instructions in `infra/README.md` to deploy on AWS.

## Using GCP

Follow the instructions in `gcp/README.md` to deploy on Google Cloud Platform.

---

## Setup Instructions

### Prerequisites
1. **Terraform** ≥ 1.5 installed ([Install Guide](https://developer.hashicorp.com/terraform/install))
2. **AWS Account** with appropriate IAM permissions for `infra/`
3. **GCP project** with billing enabled for `gcp/`

[default]
aws_access_key_id = your_access_key
aws_secret_access_key = your_secret_key
```

**Never commit credentials to the repository.**

### Step 2: Create Terraform State Bucket (Optional but Recommended)

Before using the S3 backend, create a bucket to store your Terraform state:

```bash
# Create the state bucket (bucket names are globally unique)
aws s3 mb s3://vela-terraform-state-YOUR-ACCOUNT-ID \
  --region us-east-1

# Enable versioning on the state bucket
aws s3api put-bucket-versioning \
  --bucket vela-terraform-state-YOUR-ACCOUNT-ID \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket vela-terraform-state-YOUR-ACCOUNT-ID \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

Once created, uncomment the backend configuration in `infra/main.tf` and update the bucket name.

### Step 3: Create a `.tfvars` File

Copy `example.tfvars` to a new file (not committed to git):

```bash
cd dev-ops/InfraBlueprint
cp example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:

```hcl
aws_region       = "us-east-1"
vpc_cidr         = "10.0.0.0/16"
allowed_ssh_cidr = "YOUR_IP_ADDRESS/32"  # e.g., "203.0.113.5/32"
db_username      = "velaadmin"
db_password      = "YourSecurePassword123!"
s3_bucket_name   = "vela-assets-YOUR-UNIQUE-SUFFIX"
```

**Never commit `terraform.tfvars` with real values.** Add to `.gitignore`:

```
terraform.tfvars
*.tfvars.json
!example.tfvars
```

### Step 4: Initialize and Plan

```bash
cd dev-ops/InfraBlueprint

# Download providers and modules
terraform init

# Preview changes (without making them)
terraform plan -var-file="terraform.tfvars"
```

### Step 5: Apply (Deploy)

```bash
# Deploy infrastructure
terraform apply -var-file="terraform.tfvars"

# Review the plan and type "yes" to confirm
```

### Step 6: Retrieve Outputs

```bash
# Get all outputs
terraform output

# Get specific output
terraform output ec2_public_ip
terraform output rds_endpoint
terraform output s3_bucket_name
```

### Destroy Infrastructure

```bash
terraform destroy -var-file="terraform.tfvars"

# Type "yes" to confirm deletion
```

---

## Variable Reference

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `aws_region` | string | Yes | N/A | AWS region for all resources (e.g., `us-east-1`) |
| `vpc_cidr` | string | No | `10.0.0.0/16` | CIDR block for the VPC |
| `allowed_ssh_cidr` | string | Yes | N/A | Your IP in CIDR notation to allow SSH (e.g., `203.0.113.5/32`) |
| `db_username` | string | Yes | N/A | Master username for RDS (marked sensitive) |
| `db_password` | string | Yes | N/A | Master password for RDS (marked sensitive) |
| `s3_bucket_name` | string | Yes | N/A | Globally unique S3 bucket name for static assets |

---

## Outputs

After `terraform apply`, the following outputs are available:

| Output | Description | Example |
|--------|-------------|---------|
| `ec2_public_ip` | Public IP address of the EC2 instance | `54.123.45.67` |
| `rds_endpoint` | PostgreSQL connection endpoint | `vela-postgres-db.abc123.us-east-1.rds.amazonaws.com:5432` |
| `s3_bucket_name` | Name of the S3 assets bucket | `vela-assets-unique-suffix` |

---

## Design Decisions

### 1. Private Subnets for RDS
**Decision**: Database resides in private subnets with no direct internet access.

**Why**: 
- Reduces attack surface by preventing direct access from the internet
- Follows AWS Well-Architected Framework's security pillar
- Database is only reachable from the EC2 instance via security group rules
- Multi-AZ private placement ensures high availability without exposing sensitive data

### 2. IAM Roles Instead of Access Keys
**Decision**: EC2 instance uses an IAM role with granular S3 permissions rather than embedded access keys.

**Why**:
- **Security**: No credentials stored in instance metadata or config files
- **Auditability**: CloudTrail logs which role made API calls
- **Rotation**: Credentials rotate automatically without instance reconfiguration
- **Least Privilege**: Role only grants `s3:GetObject` and `s3:PutObject` on the specific bucket
- **Best Practice**: Aligns with AWS IAM best practices and CIS benchmarks

### 3. Security Groups for Micro-segmentation
**Decision**: Separate security groups for web (`web-sg`) and database (`db-sg`) tiers.

**Why**:
- **Isolation**: DB only accepts connections from EC2, not the internet
- **Management**: Easy to modify rules per tier without affecting others
- **Debugging**: Clearer rules for troubleshooting connectivity issues
- **Scalability**: Easier to add more resources to each tier (e.g., additional EC2 instances)

### 4. S3 Versioning and Public Access Block
**Decision**: S3 bucket has versioning enabled and all public access blocked.

**Why**:
- **Versioning**: Protects against accidental overwrites or malicious modifications
- **Disaster Recovery**: Can restore previous versions of static assets
- **Public Block**: Ensures assets are only accessible via the EC2 instance's IAM role
- **Compliance**: Meets data protection and least-privilege access requirements

### 5. Multi-AZ Subnet Design
**Decision**: Both public and private subnets span two Availability Zones.

**Why**:
- **High Availability**: If one AZ fails, services in the other AZ continue
- **Resilience**: RDS in private subnets across AZs can be configured for Multi-AZ deployments
- **Future-Ready**: Easy to add auto-scaling groups or load balancers later

---

## Cost Considerations

### AWS Free Tier Coverage
- **EC2**: `t2.micro` is covered by the 12-month free tier (750 hours/month)
- **RDS**: `db.t3.micro` is covered by the 12-month free tier (750 hours/month)
- **Data Transfer**: First 1 GB/month is free; after that, charges apply

### Estimated Monthly Cost (After Free Tier)
- **EC2**: ~$9 (t2.micro on-demand)
- **RDS**: ~$20 (db.t3.micro on-demand)
- **S3**: Minimal (unless storing large volumes)
- **Data Transfer**: Variable

### Cost Optimization Tips
- Destroy resources when not in use: `terraform destroy`
- Set up AWS Budgets to monitor costs
- Consider Reserved Instances or Savings Plans for longer-term usage

---

## File Structure

```
dev-ops/InfraBlueprint/
├── README.md               # This file
├── example.tfvars          # Example variable values
├── .gitignore              # Git ignore patterns
└── infra/
    ├── main.tf             # Main resource definitions (networking, compute, database, storage)
    ├── variables.tf        # Variable definitions
    └── outputs.tf          # Output definitions
```

---

## Troubleshooting

### "Error: bucket already exists"
S3 bucket names are globally unique. Modify `s3_bucket_name` in your `.tfvars` file.

```hcl
s3_bucket_name = "vela-assets-UNIQUE-TIMESTAMP"
```

### "Error: Invalid S3 backend bucket"
Ensure the backend bucket exists and you have permissions to access it. Verify in `main.tf` that the bucket name matches what you created.

### "Error: Invalid allowed_ssh_cidr"
Ensure `allowed_ssh_cidr` includes the `/32` suffix for a single IP:

```hcl
allowed_ssh_cidr = "203.0.113.5/32"  # Correct
allowed_ssh_cidr = "203.0.113.5"     # Wrong
```

### SSH into EC2
Once deployed, get the public IP from outputs:

```bash
terraform output ec2_public_ip

# SSH into the instance
ssh -i /path/to/key.pem ec2-user@<PUBLIC_IP>
```

### Connect to RDS
From the EC2 instance, connect to the database:

```bash
psql -h <RDS_ENDPOINT> -U velaadmin -d veladb
```

---

## Security Notes

1. **Credentials**: Never commit `terraform.tfvars` with real database passwords to Git.
2. **State File**: If using local state, ensure `.terraform/` is in `.gitignore`.
3. **SSH Key**: Store your EC2 SSH key pair securely (not in the repo).
4. **AWS Keys**: Use IAM roles for EC2 instead of long-lived access keys.
5. **Sensitive Outputs**: The `db_password` is marked sensitive and won't print in logs.

---

## Next Steps (Bonus Features)

### Multi-Environment Support
Create separate `.tfvars` files for staging and production:

```bash
terraform plan -var-file="staging.tfvars"
terraform plan -var-file="production.tfvars"
```

### Modules (Refactoring)
Break the `main.tf` into reusable modules:

```
infra/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   └── database/
├── main.tf
├── variables.tf
└── outputs.tf
```

### RDS Backups
Enable automated backups and snapshots:

```hcl
resource "aws_db_instance" "main" {
  # ...
  backup_retention_period = 7  # 7 days
  backup_window           = "03:00-04:00"
  # ...
}
```

---

## Support & Documentation

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

---

## License

This project is part of the AmaliTech DEG Project-based Challenges. See the root repository LICENSE for details.

