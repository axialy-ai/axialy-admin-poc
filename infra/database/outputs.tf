/* ──────────────────────────────────────────────────────────────
 *  Outputs consumed by the GitHub Actions workflow
 *  These values are saved as repository secrets for use by
 *  the droplet deployment workflow
 * ──────────────────────────────────────────────────────────── */

output "db_host" {
  description = "MySQL cluster hostname"
  value       = digitalocean_database_cluster.axialy.host
}

output "db_port" {
  description = "MySQL cluster port"
  value       = digitalocean_database_cluster.axialy.port
}

output "db_user" {
  description = "MySQL user for Axialy applications"
  value       = digitalocean_database_user.axialy_admin.name
}

output "db_pass" {
  description = "MySQL password for Axialy applications"
  value       = digitalocean_database_user.axialy_admin.password
  sensitive   = true
}

# Additional outputs for debugging
output "db_uri" {
  description = "Full connection URI (without password)"
  value       = "mysql://${digitalocean_database_user.axialy_admin.name}@${digitalocean_database_cluster.axialy.host}:${digitalocean_database_cluster.axialy.port}"
}

output "admin_db_name" {
  description = "Admin database name"
  value       = digitalocean_database_db.admin.name
}

output "ui_db_name" {
  description = "UI database name"
  value       = digitalocean_database_db.ui.name
}
