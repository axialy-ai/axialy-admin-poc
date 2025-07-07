/* ──────────────────────────────────────────────────────────────
 *  Outputs consumed by the GitHub Actions workflow
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
