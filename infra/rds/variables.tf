variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "db_identifier" {
  description = "Identifier prefix shared by the two DBs"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage (GiB)"
  type        = number
  default     = 20
}
