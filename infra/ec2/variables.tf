variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_name" {
  description = "EC2 Name tag"
  type        = string
}

variable "instance_type" {
  description = "Instance size"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key-pair name"
  type        = string
}

variable "elastic_ip_allocation_id" {
  description = "Allocation-ID of an existing Elastic IP"
  type        = string
}
