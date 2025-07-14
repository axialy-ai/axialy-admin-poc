variable "instance_name"  { type = string }
variable "instance_type"  { type = string }
variable "key_name"       { type = string }
variable "component_tag"  { type = string }

variable "elastic_ip_allocation_id" { type = string }

variable "db_host"        { type = string }
variable "db_port"        { type = string }
variable "db_user"        { type = string }
variable "db_password"    { type = string }

variable "admin_default_user"     { type = string }
variable "admin_default_email"    { type = string }
variable "admin_default_password" { type = string }

variable "smtp_host" { type = string }
variable "smtp_port" { type = string }
variable "smtp_user" { type = string }
variable "smtp_password" { type = string }

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for the region"
  type        = string
  default     = "ami-0e34e7b9ca0ace12d" # us-west-2
}
