# ────────────────────────────────────────────
# Common / environment
# ────────────────────────────────────────────
variable "region" {
  description = "AWS region in which resources are created"
  type        = string
  default     = "us-west-2"
}

# ────────────────────────────────────────────
# RDS-specific inputs (match the CLI flags in
# your workflow)
# ────────────────────────────────────────────
variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class (e.g. db.t3.micro)"
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB"
  type        = number
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
