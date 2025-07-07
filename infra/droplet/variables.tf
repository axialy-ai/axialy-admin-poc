################################################################################
#  infra/droplet/variables.tf
#  Variables used by the Axialy Admin droplet module
################################################################################

variable "do_token" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  description = "Public SSH key that will be uploaded to DigitalOcean"
  type        = string
  sensitive   = true
}

variable "region" {
  type    = string
  default = "nyc3"
}

variable "size" {
  type    = string
  default = "s-1vcpu-2gb"
}

variable "droplet_name" {
  type = string
}

variable "repo_url" {
  type = string
}

# ── DB connection for Axialy_UI & Axialy_ADMIN ──────────────────────────
variable "db_host" { type = string }
variable "db_port" {
  type    = string
  default = "25060"            # DO managed-MySQL default
}
variable "db_user" { type = string }
variable "db_pass" {
  type      = string
  sensitive = true
}

# ── first-use admin credentials ─────────────────────────────────────────
variable "admin_default_user"   { type = string }
variable "admin_default_email"  { type = string }
variable "admin_default_password" {
  type      = string
  sensitive = true
}
