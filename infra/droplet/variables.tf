/* ──────────────────────────────────────────────────────────────
 *  Variables for the droplet module (now multi-component)
 * ──────────────────────────────────────────────────────────── */

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "droplet_name" {
  description = "Name for the droplet"
  type        = string
}

variable "region" {
  description = "DigitalOcean region where the droplet will be created"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Size of the droplet (e.g., s-1vcpu-1gb, s-1vcpu-2gb)"
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint to add to the droplet"
  type        = string
}

# Database connection variables
variable "db_host" {
  description = "Database host"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "25060"
}

variable "db_user" {
  description = "Database user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Admin defaults
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

# NEW — lets the same module serve admin / ui / api
variable "component_tag" {
  description = "Logical component name: admin | ui | api"
  type        = string
}
