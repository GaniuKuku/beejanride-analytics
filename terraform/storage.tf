module "data_lake" {
  source = "./modules/storage_bucket"

  name          = "${var.project_id}-${local.project_prefix}-data-lake"
  location      = var.region
  storage_class = "NEARLINE"
}
