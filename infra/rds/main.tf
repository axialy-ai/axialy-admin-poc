terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "random_password" "db_master" {
  length  = 20
  special = false
}

resource "aws_db_instance" "admin" {
  identifier            = "${var.db_identifier}-admin"
  allocated_storage     = var.db_allocated_storage
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = var.db_instance_class
  username              = "axialy_admin"
  password              = random_password.db_master.result
  publicly_accessible   = true
  skip_final_snapshot   = true
  deletion_protection   = false
  db_name               = "axialy_admin"
}

resource "aws_db_instance" "ui" {
  identifier            = "${var.db_identifier}-ui"
  allocated_storage     = var.db_allocated_storage
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = var.db_instance_class
  username              = "axialy_admin"
  password              = random_password.db_master.result
  publicly_accessible   = true
  skip_final_snapshot   = true
  deletion_protection   = false
  db_name               = "axialy_ui"
}

output "db_host"      { value = aws_db_instance.admin.address }
output "ui_db_host"   { value = aws_db_instance.ui.address }
output "db_port"      { value = aws_db_instance.admin.port }
output "db_user"      { value = "axialy_admin" }
output "db_pass"      { sensitive = true value = random_password.db_master.result }
