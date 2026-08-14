moved {
  from = google_storage_bucket.data_lake
  to   = module.data_lake.google_storage_bucket.this
}
