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

/*  ── MySQL / shared credentials ──────────────────────────── */
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

/*  ── Admin bootstrap creds (optional for UI/API) ─────────── */
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

/*  ── Component tag (admin | ui | api) ─────────────────────── */
variable "component_tag" {
  description = "Logical component name: admin | ui | api"
  type        = string
}

/*  ── NEW: SES SMTP relay credentials  ─────────────────────── */
variable "ses_smtp_user" {
  description = "Amazon SES SMTP user name (AKIA…)"
  type        = string
  sensitive   = true
  default     = ""          # pipelines MUST pass a value for components that send email
}

variable "ses_smtp_pass" {
  description = "Amazon SES SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ses_region" {
  description = "AWS region for the SES SMTP endpoint"
  type        = string
  default     = "us-east-1"
}
