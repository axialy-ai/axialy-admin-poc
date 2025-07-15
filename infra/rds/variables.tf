variable "region" {
  description = "AWS region in which resources are created"
  type        = string
  default     = "us-west-2"
}

variable "db_user" {
  description = "Master username for Postgres"
  type        = string
  default     = "admin"
}

variable "db_port" {
  description = "Postgres port"
  type        = number
  default     = 5432
}
