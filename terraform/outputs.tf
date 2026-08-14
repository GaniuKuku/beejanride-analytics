output "data_lake_bucket_name" {
  description = "Name of the BeejanRide data lake bucket"
  value       = module.data_lake.name
}

output "raw_dataset_id" {
  description = "BigQuery raw dataset ID"
  value       = google_bigquery_dataset.layers["beejanride_raw"].dataset_id
}

output "stg_dataset_id" {
  description = "BigQuery staging dataset ID"
  value       = google_bigquery_dataset.layers["beejanride_stg"].dataset_id
}

output "int_dataset_id" {
  description = "BigQuery intermediate dataset ID"
  value       = google_bigquery_dataset.layers["beejanride_int"].dataset_id
}

output "marts_dataset_id" {
  description = "BigQuery marts dataset ID"
  value       = google_bigquery_dataset.layers["beejanride_marts"].dataset_id
}

output "project_number" {
  description = "Google Cloud project number"
  value       = data.google_project.current.number
}

output "terraform_state_bucket_name" {
  description = "GCS bucket used for Terraform remote state"
  value       = google_storage_bucket.terraform_state.name
}
