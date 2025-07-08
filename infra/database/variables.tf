/* ──────────────────────────────────────────────────────────────
 *  Variables for the Axialy managed-DB module
 * ──────────────────────────────────────────────────────────── */

variable "do_token" {
  description = "DigitalOcean API token (set via TF_VAR_do_token)"
  type        = string
  sensitive   = true
}

variable "db_cluster_name" {
  description = "Human-readable name for the managed MySQL cluster"
  type        = string
}

variable "region" {
  description = "DigitalOcean region where the cluster will live"
  type        = string
  default     = "nyc3"
}

variable "db_size" {
  description = "Slug for the database plan/size (e.g. db-s-1vcpu-1gb)"
  type        = string
  default     = "db-s-1vcpu-1gb"   # matches the default in axialy_db.yml
}
