# infra/rds/main.tf  – at the bottom
output "db_host" {
  value = aws_db_instance.admin.address
}

output "ui_db_host" {
  value = aws_db_instance.ui.address
}

output "db_port" {
  value = aws_db_instance.admin.port
}

output "db_user" {
  value = aws_db_instance.admin.username
}

output "db_pass" {
  sensitive = true
  value     = random_password.db_master.result
}
