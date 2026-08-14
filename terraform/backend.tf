terraform {
  backend "gcs" {
    bucket = "beejanride-analytics-505416-tfstate"
    prefix = "terraform/state"
  }
}
