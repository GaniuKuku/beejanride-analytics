output "data_lake_bucket_name" {
  description = "Name of the BeejanRide data lake bucket"
  value       = module.data_lake.name
}

output "warehouse_dataset_id" {
  description = "BigQuery analytics dataset ID"
  value       = google_bigquery_dataset.warehouse.dataset_id
}

output "project_number" {
  description = "Google Cloud project number"
  value       = data.google_project.current.number
}

output "terraform_state_bucket_name" {
  description = "GCS bucket used for Terraform remote state"
  value       = google_storage_bucket.terraform_state.name
}
