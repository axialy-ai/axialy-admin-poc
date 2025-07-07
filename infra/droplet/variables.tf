variable "do_token" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

# Optional; leave blank if you don’t need it inside the droplet
variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "droplet_name" {
  type = string
}

variable "region" {
  type    = string
  default = "sfo3"
}

variable "size" {
  type    = string
  default = "s-1vcpu-2gb"
}

variable "repo_url" {
  type = string
}

# ── DB credentials ────────────────────────────────────────────────
variable "db_host" { type = string }
variable "db_port" { type = string }
variable "db_user" { type = string }
variable "db_pass" { type = string }

# ── first-time admin user ─────────────────────────────────────────
variable "admin_default_user" {
  type    = string
  default = ""
}

variable "admin_default_email" {
  type    = string
  default = ""
}

variable "admin_default_password" {
  type    = string
  default = ""
}
