variable "name" {
  description = "Name of the storage bucket"
  type        = string
}

variable "location" {
  description = "Location of the storage bucket"
  type        = string
}

variable "storage_class" {
  description = "Storage class of the bucket"
  type        = string
  default     = "STANDARD"
}
