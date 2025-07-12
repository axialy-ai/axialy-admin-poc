/* ──────────────────────────────────────────────────────────────
 *  Variables for the droplet module (multi-component)
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

/* ── MySQL / shared credentials ────────────────────────────── */
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

/* ── Admin bootstrap creds (optional for UI/API) ───────────── */
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

/* ── Component tag (admin | ui | api) ──────────────────────── */
variable "component_tag" {
  description = "Logical component name: admin | ui | api"
  type        = string
}

/* ── Amazon SES SMTP relay credentials ─────────────────────── */

/** Region of the SES SMTP endpoint (only hostname construction
    uses this for now, so a default is fine) */
variable "ses_region" {
  description = "AWS region for the SES SMTP endpoint"
  type        = string
  default     = "us-east-1"
}

/** SMTP user – REQUIRED when component_tag == "ui"            */
variable "ses_smtp_user" {
  description = "Amazon SES SMTP user name (looks like an AKIA… key)"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.component_tag == "ui" ? length(trim(var.ses_smtp_user)) > 0 : true
    error_message = "ses_smtp_user must be provided for e-mail-sending components (component_tag == \"ui\")."
  }
}

/** SMTP password – REQUIRED when component_tag == "ui"         */
variable "ses_smtp_pass" {
  description = "Amazon SES SMTP password"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.component_tag == "ui" ? length(trim(var.ses_smtp_pass)) > 0 : true
    error_message = "ses_smtp_pass must be provided for e-mail-sending components (component_tag == \"ui\")."
  }
}
