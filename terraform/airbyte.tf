resource "google_service_account" "airbyte" {
  account_id   = "beejanride-airbyte"
  display_name = "BeejanRide Airbyte"
  description  = "Service account used by Airbyte Cloud to load PostgreSQL data into BigQuery raw layer"
}

resource "google_bigquery_dataset_iam_member" "airbyte_raw_data_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.layers["beejanride_raw"].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.airbyte.email}"
}

resource "google_project_iam_member" "airbyte_job_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.airbyte.email}"
}
