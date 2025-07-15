variable "region" {
  type    = string
  default = "us-west-2"
}

variable "db_identifier" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}
