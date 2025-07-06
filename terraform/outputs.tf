output "droplet_ip" {
  value       = digitalocean_droplet.axialy_admin.ipv4_address
  description = "The public IP address of the Axialy Admin droplet"
}

output "db_host" {
  value       = digitalocean_database_cluster.axialy_mysql.host
  description = "Database cluster hostname"
  sensitive   = true
}

output "db_port" {
  value       = digitalocean_database_cluster.axialy_mysql.port
  description = "Database cluster port"
}

output "db_admin_user" {
  value       = digitalocean_database_user.admin_user.name
  description = "Admin database username"
  sensitive   = true
}

output "db_admin_password" {
  value       = digitalocean_database_user.admin_user.password
  description = "Admin database password"
  sensitive   = true
}

output "db_ui_user" {
  value       = digitalocean_database_user.ui_user.name
  description = "UI database username"
  sensitive   = true
}

output "db_ui_password" {
  value       = digitalocean_database_user.ui_user.password
  description = "UI database password"
  sensitive   = true
}
