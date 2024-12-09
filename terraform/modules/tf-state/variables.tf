variable "TF_STATE_BUCKET_NAME" {
  type        = string
  description = "The name of the S3 bucket to store the Terraform state"

  validation {
    condition     = can(regex("^([a-z0-9]{1}[a-z0-9-]{1,61}[a-z0-9]{1})$", var.TF_STATE_BUCKET_NAME)) && length(var.TF_STATE_BUCKET_NAME) <= 63 && length(var.TF_STATE_BUCKET_NAME) >= 1
    error_message = "The TF_STATE_BUCKET_NAME must be between 1 and 63 characters, start with a lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "TABLE_NAME" {
  type        = string
  description = "The name of the DynamoDB table to store the Terraform state lock"
}