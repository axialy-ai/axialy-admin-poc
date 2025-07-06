############  Cluster-wide ############
output "db_host" { value = digitalocean_database_cluster.axialy.host }
output "db_port" { value = digitalocean_database_cluster.axialy.port }

############  ADMIN DB ############
output "admin_db_name" { value = digitalocean_database_db.admin.name }
output "admin_db_user" { value = digitalocean_database_user.axialy_admin.name }
output "admin_db_pass" {
  value     = digitalocean_database_user.axialy_admin.password
  sensitive = true
}

############  UI DB ############
output "ui_db_name" { value = digitalocean_database_db.ui.name }
output "ui_db_user" { value = digitalocean_database_user.axialy_ui.name }
output "ui_db_pass" {
  value     = digitalocean_database_user.axialy_ui.password
  sensitive = true
}
