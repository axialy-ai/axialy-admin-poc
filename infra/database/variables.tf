variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "db_cluster_name" {
  description = "Name for the DigitalOcean DB cluster"
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug (nyc3, sfo3, …)"
  type        = string
}

variable "db_size" {
  description = "Size slug for the DB cluster (e.g. db-s-1vcpu-1gb)"
  type        = string
}
