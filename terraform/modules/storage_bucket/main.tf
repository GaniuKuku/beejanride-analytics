resource "google_storage_bucket" "this" {
  name     = var.name
  location = var.location

  storage_class = var.storage_class

  uniform_bucket_level_access = true
}
