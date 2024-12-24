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

variable "DB_HOST" {
  description = "DB Host"
  type        = string
}

variable "DB_NAME" {
  description = "DB Name"
  type        = string
}

variable "DB_USER" {
  description = "DB User"
  type        = string
}

variable "DB_PASSWORD" {
  description = "DB Password"
  type        = string
}

variable "IMAGE_TAG" {
  description = "Image tag"
  type        = string
}