variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_name" {
  description = "Tag / name for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key-pair name for SSH access"
  type        = string
}

variable "elastic_ip_allocation_id" {
  description = "EIP allocation ID to associate with the instance"
  type        = string
}
