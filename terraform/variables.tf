variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "ssh_fingerprint" {
  description = "SSH key fingerprint for droplet access"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet size"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "db_cluster_size" {
  description = "Database cluster size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "admin_default_user" {
  description = "Default admin username"
  type        = string
  sensitive   = true
}

variable "admin_default_email" {
  description = "Default admin email"
  type        = string
  sensitive   = true
}

variable "admin_default_password" {
  description = "Default admin password"
  type        = string
  sensitive   = true
}
