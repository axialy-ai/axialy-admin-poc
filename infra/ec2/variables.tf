variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type = string
}

variable "elastic_ip_allocation_id" {
  type = string
}
