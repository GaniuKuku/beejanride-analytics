resource "google_storage_bucket" "data_lake" {
  name     = "${var.project_id}-${local.project_prefix}-data-lake"
  location = var.region

  storage_class = "NEARLINE"

  uniform_bucket_level_access = true
}
