# Vela Payments Infrastructure as Code (GCP)

This project provisions a reproducible, secure cloud infrastructure for Vela Payments using Terraform on **Google Cloud Platform**.

The infrastructure is designed to be destroyed and recreated with a single command, and follows GCP security best practices: private database access, least-privilege service accounts, locked-down storage, and tag-based firewall rules.

---

## Where to Go

All Terraform code and detailed setup instructions live in the [`gcp/`](./gcp) directory.

👉 **See [`gcp/README.md`](./gcp/README.md) for:**
- Architecture overview
- Step-by-step deployment instructions
- Variable reference
- Outputs
- Design decisions
- Troubleshooting

---

## Quick Start

```bash
cd gcp
gcloud auth application-default login
cp example.tfvars terraform.tfvars
# edit terraform.tfvars with your values

terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## File Structure

```
dev-ops/InfraBlueprint/
├── README.md          # This file
└── gcp/
    ├── README.md       # Full GCP setup & documentation
    ├── main.tf         # Main resource definitions
    ├── variables.tf    # Variable definitions
    ├── outputs.tf      # Output definitions
    └── example.tfvars  # Example variable values
```

---

## License

This project is part of the AmaliTech DEG Project-based Challenges. See the root repository LICENSE for details.
