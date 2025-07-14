terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_password" "master" {
  length  = 24
  special = true
}

resource "aws_db_instance" "axialy" {
  identifier              = var.db_instance_id
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  username                = var.master_username
  password                = random_password.master.result
  skip_final_snapshot     = true
  publicly_accessible     = true
  delete_automated_backups = true
}

# --- create axialy_admin & axialy_ui schemas and service user ------------
provider "mysql" {
  endpoint = aws_db_instance.axialy.address
  port     = aws_db_instance.axialy.port
  username = aws_db_instance.axialy.username
  password = aws_db_instance.axialy.password
  tls      = "true"
}

resource "mysql_database" "admin" { name = "axialy_admin" }
resource "mysql_database" "ui"    { name = "axialy_ui" }

resource "random_password" "svc" {
  length  = 24
  special = true
}

resource "mysql_user" "svc" {
  user               = "axialy_admin"
  host               = "%"
  plaintext_password = random_password.svc.result
}

resource "mysql_grant" "svc" {
  user       = mysql_user.svc.user
  host       = mysql_user.svc.host
  database   = "*"
  privileges = ["ALL"]
}

# -------------------- outputs -------------------------------------------
output "db_host" { value = aws_db_instance.axialy.address }
output "db_port" { value = aws_db_instance.axialy.port }
output "db_user" { value = mysql_user.svc.user }
output "db_pass" { value = mysql_user.svc.plaintext_password sensitive = true }
