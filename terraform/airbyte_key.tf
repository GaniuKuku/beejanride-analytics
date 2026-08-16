resource "google_service_account_key" "airbyte" {
  service_account_id = google_service_account.airbyte.name
}
