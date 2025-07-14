variable "db_instance_id"     { type = string }
variable "db_instance_class"  { type = string }
variable "allocated_storage"  { type = number }

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "master_username" {
  type    = string
  default = "axialy_root"
}
