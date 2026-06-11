# Vela Payments GCP Infrastructure as Code

This directory provisions a reproducible Google Cloud infrastructure for Vela Payments using Terraform.

## Architecture Overview

- VPC network with a public subnet and private subnet
- Compute instance in the public subnet with HTTP/HTTPS/SSH firewall rules
- Cloud SQL PostgreSQL instance on a private network
- Google Cloud Storage bucket with uniform access and versioning
- Service account for VM access to GCS

## Setup Instructions

### Prerequisites
- **GCP project** with billing enabled
- **Terraform** ≥ 1.5 installed
- **Google Cloud SDK** installed and authenticated
- **gcloud** configured to the target project:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Step 1: Configure credentials

Terraform can authenticate using the Cloud SDK credentials or a service account key.

```bash
gcloud auth application-default login
```

### Step 2: Create example tfvars

```bash
cd dev-ops/InfraBlueprint/gcp
cp example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` with your values.

### Step 3: Initialize and plan

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
```

### Step 4: Apply

```bash
terraform apply -var-file="terraform.tfvars"
```

### Outputs
- `web_instance_ip`
- `cloud_sql_connection_name`
- `gcs_bucket_name`
