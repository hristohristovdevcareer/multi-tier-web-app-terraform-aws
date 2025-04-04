variable "BUCKET_NAME" {
  type        = string
  description = "The name of the S3 bucket to store the Terraform state"

  validation {
    condition     = can(regex("^([a-z0-9]{1}[a-z0-9-]{1,61}[a-z0-9]{1})$", var.BUCKET_NAME)) && length(var.BUCKET_NAME) <= 63 && length(var.BUCKET_NAME) >= 1
    error_message = "The BUCKET_NAME must be between 1 and 63 characters, start with a lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "ENABLE_STATE_MANAGEMENT" {
  type        = bool
  description = "Enable state management"
}

variable "REGION" {
  type        = string
  description = "The region to create the resources in"
}

variable "TF_PROFILE" {
  type        = string
  description = "The AWS profile to use"
}
