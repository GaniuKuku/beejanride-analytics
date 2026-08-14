resource "google_bigquery_dataset" "warehouse" {
  dataset_id = "beejanride_analytics"
  project    = var.project_id
  location   = "EU"

  labels = {
    environment = local.environment
  }
}
