variable "region" {
  description = "AWS region for the EC2 instance"
  type        = string
  default     = "us-west-2"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key-pair name"
  type        = string
}

variable "elastic_ip_allocation_id" {
  description = "Allocation-ID of an existing Elastic IP (in the same region)"
  type        = string
}

# Only needed if the account’s default VPC was deleted:
variable "vpc_id" {
  description = "Optional VPC ID to host the instance"
  type        = string
  default     = ""
}
