resource "google_bigquery_dataset" "layers" {
  for_each = toset([
    "beejanride_raw",
    "beejanride_stg",
    "beejanride_int",
    "beejanride_marts"
  ])

  dataset_id = each.value
  location   = var.region

  labels = {
    environment = local.environment
    layer       = replace(each.value, "beejanride_", "")
  }
}
