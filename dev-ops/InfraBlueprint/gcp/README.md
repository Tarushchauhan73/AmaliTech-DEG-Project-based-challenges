# Vela Payments Infrastructure as Code (GCP)

This directory provisions a reproducible, secure cloud infrastructure for Vela Payments using Terraform on **Google Cloud Platform**.

The infrastructure follows GCP security best practices: a private (non-internet-facing) database, a least-privilege service account for the web tier, a locked-down storage bucket, and tag-based firewall rules. It is designed to be destroyed and recreated with a single command.

---

## ✅ Verified Deployment

This configuration was successfully deployed and torn down end-to-end on **June 11, 2026**.

### Terraform Apply — Outputs

```
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

cloud_sql_connection_name = "project-xxxxxxxx-xxxx-xxxx-xxx:us-central1:vela-postgres-db"
gcs_bucket_name           = "vela-assets-tarush-2026"
web_instance_ip           = "34.132.59.129"
```

### What Was Verified

| Check | Result |
|---|---|
| `terraform init` | ✅ Initialized successfully |
| `terraform plan` | ✅ 18 resources planned, 0 errors |
| `terraform apply` | ✅ All 18 resources created |
| SSH into VM (`gcloud compute ssh`) | ✅ Connected successfully to Ubuntu 24.04 |
| VM status in Console | ✅ `vela-web-server` — Running, `us-central1-a` |
| Cloud SQL status in Console | ✅ `vela-postgres-db` — Running, PostgreSQL 15 |
| Cloud Storage bucket in Console | ✅ `vela-assets-tarush-2026` — Not public, versioning + soft delete enabled |
| `terraform destroy` | ✅ All 18 resources destroyed cleanly |

### Screenshots

Screenshots from the verified run are included in [`screenshots/`](./screenshots):

1. `01-vm-instance.png` — Compute Engine VM details (Status: Running)
 <img width="637" height="357" alt="Screenshot 2026-06-11 at 1 44 29 PM" src="https://github.com/user-attachments/assets/3f557ed5-bfb3-4c21-bad5-eaed4c5f7ba2" />
 
 <img width="1440" height="800" alt="Screenshot 2026-06-11 at 1 34 52 PM" src="https://github.com/user-attachments/assets/3b2bd1e2-bcb6-494a-9fb5-f7a377c3cfc6" />

  
2. `02-cloud-sql-overview.png` — Cloud SQL instance overview & operations log
  <img width="1440" height="753" alt="Screenshot 2026-06-11 at 1 37 38 PM" src="https://github.com/user-attachments/assets/95271f6e-54b2-41fc-b782-c0c371a881c3" />
  
  <img width="1440" height="900" alt="Screenshot 2026-06-11 at 1 38 10 PM" src="https://github.com/user-attachments/assets/bb353810-cb2c-4fdf-9ccb-fdd0eb6d91c1" />


3. `03-storage-bucket.png` — Cloud Storage bucket details (Not public, versioning enabled)
<img width="639" height="333" alt="Screenshot 2026-06-11 at 5 52 58 PM" src="https://github.com/user-attachments/assets/a794e8c3-1e8a-4679-b237-c948333d853c" />

---

## AWS → GCP Service Mapping

This project is a GCP adaptation of an AWS-based reference architecture. Each AWS service maps to a GCP equivalent:

| AWS (reference) | GCP (this implementation) |
|---|---|
| VPC | VPC Network (`vela-network`) |
| Public/Private Subnets | Subnetworks (`vela-public-subnet`, `vela-private-subnet`) |
| Internet Gateway | Default internet route (implicit) |
| EC2 `t2.micro` | Compute Engine `e2-micro` |
| Security Groups | Firewall Rules (tag-based, `vela-web`) |
| IAM Role + Instance Profile | Service Account (`vela-web-sa`) |
| RDS PostgreSQL 15 | Cloud SQL for PostgreSQL 15 (`vela-postgres-db`) |
| S3 Bucket | Cloud Storage Bucket (`vela-assets-*`) |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet (0.0.0.0/0)                     │
└────────────────────────────────┬────────────────────────────────┘
                                  │ :80, :443
                                  │ :22 (your IP only)
                                  ▼
                      ┌──────────────────────┐
                      │  GCP VPC 10.0.0.0/16  │
                      │   "vela-network"      │
                      └──────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
        ┌───────────▼──────────┐    ┌──────────▼───────────────┐
        │   Public Subnet       │    │   Private Subnet         │
        │   10.0.1.0/24         │    │   10.0.10.0/24            │
        │                       │    │                           │
        │  ┌─────────────────┐  │    │  ┌─────────────────────┐  │
        │  │ Compute Engine  │  │    │  │ Cloud SQL PostgreSQL│  │
        │  │ e2-micro        │──┼────┼─▶│ db-f1-micro         │  │
        │  │ tag: vela-web   │  │    │  │ Private IP only      │  │
        │  │ SA: vela-web-sa │  │    │  │ (no public IP)       │  │
        │  └─────────────────┘  │    │  └─────────────────────┘  │
        └───────────────────────┘    └───────────────────────────┘

┌────────────────────────────────────┐
│   Cloud Storage Bucket               │
│   vela-assets-*                      │
│   - Public access prevented          │
│   - Uniform bucket-level access      │
│   - Versioning enabled                │
│   - VM access via vela-web-sa        │
│     (roles/storage.objectAdmin)      │
└────────────────────────────────────┘
```

---

## Components

### Networking
- **VPC**: `vela-network` — custom-mode, no auto-created subnets
- **Public Subnet** (`10.0.1.0/24`): hosts the web tier VM with an external IP
- **Private Subnet** (`10.0.10.0/24`): reserved for the database tier
- **Private Services Connection**: dedicated peered IP range so Cloud SQL gets a private IP inside the VPC

### Compute
- **Compute Engine Instance** `vela-web-server`: Ubuntu 24.04 LTS, `e2-micro`, tagged `vela-web`
- **Firewall — `vela-web-http-https`**: allows inbound 80/443 from `0.0.0.0/0`
- **Firewall — `vela-web-ssh`**: allows inbound 22 only from `allowed_ssh_cidr` (your IP)
- **Service Account** `vela-web-sa`: attached to the VM, granted `roles/storage.objectAdmin` on the assets bucket only

### Database
- **Cloud SQL Instance** `vela-postgres-db`: PostgreSQL 15, `db-f1-micro`, zonal
- **Private IP only** (`ipv4_enabled = false`) — not reachable from the internet
- **Database** `veladb` and **user** `velaadmin` created via Terraform, credentials parameterized

### Storage
- **Cloud Storage Bucket** `vela-assets-*`: for static assets
- **Public access prevention**: enforced
- **Uniform bucket-level access**: enabled
- **Versioning**: enabled for disaster recovery

---

## Setup Instructions

### Prerequisites
1. **GCP account** with billing enabled (free trial credit covers this easily)
2. **Terraform** ≥ 1.5 ([Install Guide](https://developer.hashicorp.com/terraform/install))
3. **Google Cloud SDK** (`gcloud`) installed

### Step 1 — Authenticate gcloud

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Step 2 — Set up Application Default Credentials (for Terraform)

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

### Step 3 — Enable required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  servicenetworking.googleapis.com
```

> Wait 1–2 minutes after enabling for the changes to propagate before running `terraform apply`.

### Step 4 — Create `terraform.tfvars`

```bash
cp example.tfvars terraform.tfvars
```

Edit with your values:

```hcl
gcp_project         = "your-gcp-project-id"
gcp_region          = "us-central1"
instance_zone       = "us-central1-a"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.10.0/24"

# Find yours: curl https://checkip.amazonaws.com
allowed_ssh_cidr    = "YOUR_IP/32"

gcs_bucket_name     = "vela-assets-your-unique-suffix"
db_name             = "veladb"
db_username         = "velaadmin"
db_password         = "REPLACE_WITH_STRONG_PASSWORD"
```

**Never commit `terraform.tfvars`** — it's already in `.gitignore`.

### Step 5 — Init, Plan, Apply

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

> ⏱ `terraform apply` takes **10–15 minutes**, mostly waiting for the Cloud SQL instance to provision. This is normal — let it run.

### Step 6 — Retrieve Outputs

```bash
terraform output
terraform output web_instance_ip
terraform output cloud_sql_connection_name
terraform output gcs_bucket_name
```

### Step 7 — Verify

**SSH into the VM:**
```bash
gcloud compute ssh vela-web-server --zone=us-central1-a
```

**Check Cloud SQL** (from the GCP Console → SQL → `vela-postgres-db`, or via Cloud SQL Studio)

**Check the bucket** (GCP Console → Cloud Storage → Buckets → `vela-assets-*`)

---

## ⚠️ Destroy Infrastructure (Important — Avoid Charges)

Cloud SQL (`db-f1-micro`) costs roughly **$10/month** if left running — it is **not** covered by the GCP "Always Free" tier. Always destroy when you're done testing:

```bash
terraform destroy -var-file="terraform.tfvars"
```

> ⏱ Takes **5–10 minutes**, mostly Cloud SQL deletion. Type `yes` to confirm.

---

## Variable Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `gcp_project` | Yes | N/A | Your GCP project ID |
| `gcp_region` | No | `us-central1` | GCP region for regional resources |
| `instance_zone` | No | `us-central1-a` | GCP zone for the Compute Engine VM |
| `public_subnet_cidr` | No | `10.0.1.0/24` | CIDR for the public subnet |
| `private_subnet_cidr` | No | `10.0.10.0/24` | CIDR for the private subnet |
| `allowed_ssh_cidr` | Yes | N/A | Your IP in CIDR notation for SSH (e.g. `203.0.113.5/32`) |
| `gcs_bucket_name` | Yes | N/A | Globally unique GCS bucket name |
| `db_name` | No | `veladb` | Default database name |
| `db_username` | Yes | N/A | Cloud SQL master username |
| `db_password` | Yes | N/A | Cloud SQL master password (sensitive) |

---

## Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `web_instance_ip` | Public IP of the Compute Engine VM | `34.132.59.129` |
| `cloud_sql_connection_name` | Cloud SQL connection name (for Cloud SQL Auth Proxy) | `project-id:us-central1:vela-postgres-db` |
| `gcs_bucket_name` | Name of the Cloud Storage assets bucket | `vela-assets-tarush-2026` |

---

## Design Decisions

### Private IP for Cloud SQL
The database has `ipv4_enabled = false` — it has no public IP and is only reachable from within the VPC via the private services connection. This eliminates internet-facing attack surface entirely, mirroring the AWS RDS "not publicly accessible" requirement.

### Service Account Instead of Static Keys
The VM runs as `vela-web-sa`, a service account scoped to `roles/storage.objectAdmin` on a single bucket — no embedded credentials, no keys to rotate or leak. GCP issues short-lived credentials automatically and logs every API call to Cloud Audit Logs.

### Tag-Based Firewall Rules
Firewall rules target instances via the `vela-web` network tag rather than applying VPC-wide. This mirrors AWS security-group micro-segmentation: only tagged instances receive the HTTP/HTTPS/SSH rules, making it easy to add more VMs to the same tier without exposing unrelated resources.

### Versioned, Locked-Down Storage Bucket
`public_access_prevention = "enforced"` plus `versioning { enabled = true }` guarantees no accidental public exposure regardless of object-level ACLs, while versioning protects against accidental deletion or overwrite.

### Multi-Subnet Design with Private Services Connection
Separate public/private subnets, plus a dedicated peered IP range for Cloud SQL, keep the database tier logically isolated from the web tier's address space. The private services connection is GCP's required mechanism for giving Cloud SQL a private IP inside a custom VPC — the closest equivalent to an AWS DB subnet group.

---

## Cost Considerations

### Free Trial Coverage
- New GCP accounts get **$300 free credit for 90 days** — covers this entire stack many times over
- **Compute Engine** `e2-micro` is part of the "Always Free" tier in `us-central1`, `us-west1`, `us-east1`
- **Cloud Storage**: 5 GB Always Free in the same regions
- **Cloud SQL** `db-f1-micro` is **not** part of Always Free — approx. **$10/month** if left running

### Cost Optimization
- Always run `terraform destroy` when not actively testing
- Set up a [GCP Budget Alert](https://cloud.google.com/billing/docs/how-to/budgets) to monitor spend
- Use `us-central1`, `us-west1`, or `us-east1` to qualify for Always Free Compute Engine

---

## Troubleshooting

### "Compute Engine API has not been used in project ... before or it is disabled"
APIs were just enabled and haven't propagated yet. Wait 1–2 minutes and re-run `terraform apply` — it will pick up where it left off.

### "Error 404: The resource '.../images/family/ubuntu-2404-lts' was not found"
Use the correct image reference format: `ubuntu-os-cloud/ubuntu-2404-lts-amd64` (not the `projects/.../global/images/family/...` path).

### "Error: Unsupported argument" (e.g. `labels` on a network/subnetwork, or `project` on `google_service_networking_connection`)
These arguments aren't supported by the `hashicorp/google` v4.x provider for those resource types. Remove them — the resources inherit the project from the provider block.

### "failed to delete instance because deletion_protection is set to true"
Add `deletion_protection = false` to the `google_sql_database_instance` resource, run `terraform apply` once to update the attribute, then `terraform destroy`.

### "Error disabling service ... is depended on by ... cloudapis.googleapis.com"
Some project-level APIs (compute, storage) can't be cleanly disabled via Terraform because other Google-managed services depend on them. This is harmless — remove the `google_project_service` resources from state with `terraform state rm <resource>` and from `main.tf`. Leaving these APIs enabled costs nothing.

### "Invalid allowed_ssh_cidr"
Must include the `/32` suffix for a single IP:
```hcl
allowed_ssh_cidr = "203.0.113.5/32"  # Correct
allowed_ssh_cidr = "203.0.113.5"     # Wrong
```

### SSH connection issues
First-time SSH may need ~60 seconds for the key to propagate to the VM metadata. If it fails, wait and retry:
```bash
gcloud compute ssh vela-web-server --zone=us-central1-a
```

---

## File Structure

```
dev-ops/InfraBlueprint/gcp/
├── README.md            # This file
├── main.tf              # Main resource definitions
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── example.tfvars       # Example variable values
├── terraform.tfvars      # Your real values (gitignored)
└── screenshots/          # Verified deployment screenshots
    ├── 01-vm-instance.png
    ├── 02-cloud-sql-overview.png
    └── 03-storage-bucket.png
```

---

## License

This project is part of the AmaliTech DEG Project-based Challenges. See the root repository LICENSE for details.
