variable "gcp_project" {
  description = "GCP project ID to deploy resources into."
  type        = string
}

variable "gcp_region" {
  description = "GCP region to deploy resources into."
  type        = string
  default     = "us-central1"
}

variable "instance_zone" {
  description = "GCP zone for the compute instance."
  type        = string
  default     = "us-central1-a"
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private subnet."
  type        = string
  default     = "10.0.10.0/24"
}

variable "allowed_ssh_cidr" {
  description = "Your IP address in CIDR notation allowed to SSH into the VM."
  type        = string
}

variable "gcs_bucket_name" {
  description = "Globally unique name for the GCS static assets bucket."
  type        = string
}

variable "db_name" {
  description = "Database name for the Cloud SQL instance."
  type        = string
  default     = "veladb"
}

variable "db_username" {
  description = "Master username for the Cloud SQL instance."
  type        = string
}

variable "db_password" {
  description = "Master password for the Cloud SQL instance."
  type        = string
  sensitive   = true
}
