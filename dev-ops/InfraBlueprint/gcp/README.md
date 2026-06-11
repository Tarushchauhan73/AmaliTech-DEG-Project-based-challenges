# Vela Payments Infrastructure as Code (GCP)

This project provisions a reproducible, secure cloud infrastructure for Vela Payments using Terraform on **Google Cloud Platform**.

## AWS to GCP Service Mapping

| AWS (original spec) | GCP (this implementation) |
|---|---|
| VPC | VPC Network |
| Public/Private Subnets | Subnetworks |
| Internet Gateway | Default internet route (implicit) |
| EC2 t2.micro | Compute Engine `e2-micro` |
| Security Groups | Firewall Rules |
| IAM Role + Instance Profile | Service Account |
| RDS PostgreSQL 15 | Cloud SQL for PostgreSQL 15 |
| S3 Bucket | Cloud Storage Bucket |

## Setup Instructions

### Prerequisites
1. GCP Account with billing enabled
2. Terraform >= 1.5
3. gcloud CLI installed and authenticated

### Step 1: Create a GCP Project & Enable APIs

```bash
cd /workspaces/AmaliTech-DEG-Project-based-challenges/dev-ops/InfraBlueprint

# Step 1: Save the router content (currently in gcp/README.md) to the top-level README
cp gcp/README.md README.md

# Step 2: Write the full GCP documentation into gcp/README.md
cat > gcp/README.md << 'GCPEOF'
# Vela Payments Infrastructure as Code (GCP)

This project provisions a reproducible, secure cloud infrastructure for Vela Payments using Terraform on **Google Cloud Platform**.

## AWS to GCP Service Mapping

| AWS (original spec) | GCP (this implementation) |
|---|---|
| VPC | VPC Network |
| Public/Private Subnets | Subnetworks |
| Internet Gateway | Default internet route (implicit) |
| EC2 t2.micro | Compute Engine `e2-micro` |
| Security Groups | Firewall Rules |
| IAM Role + Instance Profile | Service Account |
| RDS PostgreSQL 15 | Cloud SQL for PostgreSQL 15 |
| S3 Bucket | Cloud Storage Bucket |

## Setup Instructions

### Prerequisites
1. GCP Account with billing enabled
2. Terraform >= 1.5
3. gcloud CLI installed and authenticated

### Step 1: Create a GCP Project & Enable APIs

```bash
gcloud projects create vela-payments-infra --name="Vela Payments"
gcloud config set project vela-payments-infra

gcloud services enable \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  servicenetworking.googleapis.com
```

### Step 2: Authenticate

```bash
gcloud auth application-default login
```

### Step 3: Create terraform.tfvars

```bash
cp example.tfvars terraform.tfvars
```

Edit with your values:

```hcl
gcp_project_id   = "vela-payments-infra"
allowed_ssh_cidr = "YOUR_IP/32"
db_username      = "velaadmin"
db_password      = "YourSecurePassword123!"
gcs_bucket_name  = "vela-assets-unique-suffix"
```

### Step 4: Init, Plan, Apply

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Outputs

```bash
terraform output vm_public_ip
terraform output db_connection_name
terraform output gcs_bucket_name
```

### Destroy

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Variable Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| gcp_project_id | Yes | N/A | Your GCP project ID |
| gcp_region | No | us-central1 | GCP region |
| gcp_zone | No | us-central1-a | GCP zone |
| allowed_ssh_cidr | Yes | N/A | Your IP for SSH access |
| db_username | Yes | N/A | Cloud SQL username |
| db_password | Yes | N/A | Cloud SQL password |
| gcs_bucket_name | Yes | N/A | Globally unique bucket name |
| machine_type | No | e2-micro | Compute Engine machine type |
| db_tier | No | db-f1-micro | Cloud SQL tier |

## Design Decisions

### Private IP for Cloud SQL
Database has no public IP - only reachable from within the VPC.

### Service Accounts Instead of Static Keys
VM uses an attached Service Account scoped to a single bucket.

### Tag-Based Firewall Rules
Firewall rules target instances via the `web` network tag.

### Versioned, Locked-Down Storage Bucket
Public access prevention enforced, versioning enabled.

## Troubleshooting

**Bucket already exists**: GCS bucket names are globally unique - change `gcs_bucket_name`.

**Invalid allowed_ssh_cidr**: Must include `/32` suffix, e.g. `203.0.113.5/32`.

## License

This project is part of the AmaliTech DEG Project-based Challenges.
