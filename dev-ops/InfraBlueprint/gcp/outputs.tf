output "web_instance_ip" {
  description = "Public IP address of the GCP compute instance."
  value       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL instance connection name."
  value       = google_sql_database_instance.main.connection_name
}

output "gcs_bucket_name" {
  description = "Name of the GCS static assets bucket."
  value       = google_storage_bucket.assets.name
}
