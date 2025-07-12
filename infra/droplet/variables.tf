/* ──────────────────────────────────────────────────────────────
 *  Variables for the droplet module (now multi-component)
 * ──────────────────────────────────────────────────────────── */

variable "do_token"          { description = "DigitalOcean API token"          type = string  sensitive = true }
variable "droplet_name"      { description = "Name for the droplet"            type = string }
variable "region"            { description = "DigitalOcean region"             type = string  default = "nyc3" }
variable "droplet_size"      { description = "Droplet size slug"               type = string  default = "s-1vcpu-2gb" }
variable "ssh_key_fingerprint" { description = "SSH key fingerprint"           type = string }

/* database */
variable "db_host"           { description = "DB host"                         type = string  sensitive = true }
variable "db_port"           { description = "DB port"                         type = string  default   = "25060" }
variable "db_user"           { description = "DB user"                         type = string  sensitive = true }
variable "db_password"       { description = "DB password"                     type = string  sensitive = true }

/* admin bootstrap defaults */
variable "admin_default_user"     { description = "Default admin username"   type = string  sensitive = true }
variable "admin_default_email"    { description = "Default admin e-mail"     type = string  sensitive = true }
variable "admin_default_password" { description = "Default admin password"   type = string  sensitive = true }

/* tag so the same module works for admin|ui|api */
variable "component_tag" { description = "Logical component tag" type = string }

/* ─────────── NEW – smart-host relay details ─────────── */
variable "smtp_host"     { description = "SMTP relay host (e.g. axiaba.com)" type = string }
variable "smtp_port"     { description = "SMTP port (465 TLS or 587 STARTTLS)" type = string default = "465" }
variable "smtp_user"     { description = "SMTP username"  type = string  sensitive = true }
variable "smtp_password" { description = "SMTP password"  type = string  sensitive = true }
