data "google_project" "current" {
  project_id = var.project_id
}

resource "google_storage_bucket" "terraform_state" {
  name                        = "${var.project_id}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

# Changed from a raw resource to your module call!
module "data_lake" {
  source        = "./modules/storage_bucket"
  name          = "${var.project_id}-beejanride-data-lake"
  location      = var.region
  storage_class = "NEARLINE"
}

resource "google_bigquery_dataset" "layers" {
  for_each = toset([
    "beejanride_raw",
    "beejanride_stg",
    "beejanride_int",
    "beejanride_marts",
  ])

  dataset_id = each.value
  location   = var.region

  labels = {
    environment = "dev"
    layer       = replace(each.value, "beejanride_", "")
  }
}

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

resource "google_service_account_key" "airbyte" {
  service_account_id = google_service_account.airbyte.name
}
