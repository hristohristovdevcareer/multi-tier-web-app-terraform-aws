variable "PROJECT_NAME" {
  description = "Project name"
  type        = string
}

variable "REGION" {
  description = "Region"
  type        = string
}

variable "SERVICES" {
  description = "Services"
  type        = map(any)
}
