variable "project_id" {
  description = "GCP project ID for the BeejanRide analytics platform"
  type        = string
}

variable "region" {
  description = "GCP region for BeejanRide resources"
  type        = string
  default     = "europe-west2"
}
