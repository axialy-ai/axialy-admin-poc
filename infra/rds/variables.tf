# infra/rds/variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_identifier" {
  description = "Identifier prefix for DB instances"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage (GiB)"
  type        = number
  default     = 20
}
