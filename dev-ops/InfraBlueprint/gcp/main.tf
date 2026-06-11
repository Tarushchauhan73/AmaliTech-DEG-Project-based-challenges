terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

locals {
  common_labels = {
    project = "vela-payments"
  }
}

resource "google_compute_network" "main" {
  name                    = "vela-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC network for Vela Payments GCP infrastructure"
  project                 = var.gcp_project

}

resource "google_compute_subnetwork" "public" {
  name          = "vela-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
  private_ip_google_access = true

}

resource "google_compute_subnetwork" "private" {
  name          = "vela-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
  private_ip_google_access = true

}

resource "google_compute_firewall" "web_http_https" {
  name    = "vela-web-http-https"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vela-web"]

  direction = "INGRESS"
  project   = var.gcp_project
}

resource "google_compute_firewall" "web_ssh" {
  name    = "vela-web-ssh"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["vela-web"]

  direction = "INGRESS"
  project   = var.gcp_project
}

resource "google_service_account" "web_sa" {
  account_id   = "vela-web-sa"
  display_name = "Vela Web Server Service Account"
  project      = var.gcp_project
}

resource "google_storage_bucket" "assets" {
  name          = var.gcs_bucket_name
  location      = var.gcp_region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = local.common_labels
  project = var.gcp_project
}

resource "google_storage_bucket_iam_member" "assets_web_sa" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.web_sa.email}"
}

resource "google_compute_instance" "web" {
  name         = "vela-web-server"
  project      = var.gcp_project
  zone         = var.instance_zone
  machine_type = "e2-micro"

  tags = ["vela-web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.public.id
    access_config {}
  }

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  labels = local.common_labels
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "vela-private-ip-range"
  project       = var.gcp_project
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "main" {
  name             = "vela-postgres-db"
  project          = var.gcp_project
  deletion_protection = false
  region           = var.gcp_region
  database_version = "POSTGRES_15"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }

    activation_policy = "ALWAYS"
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "app_db" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
  project  = var.gcp_project
}

resource "google_sql_user" "main" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  project  = var.gcp_project
  password = var.db_password
}
