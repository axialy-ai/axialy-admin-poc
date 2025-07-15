# ────────── network context ──────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.db_identifier}-subnets"
  subnet_ids = data.aws_subnets.default.ids
  tags       = { Name = "${var.db_identifier}-subnets" }
}

# ────────── master password ──────────
resource "random_password" "db_master" {
  length           = 16
  override_special = "!#$%^&*()-_=+[]{}:.,?"   # removes / @ " and space
  special          = true
}

# ────────── security group ──────────
resource "aws_security_group" "rds" {
  name        = "${var.db_identifier}-rds-sg"
  description = "Allow MySQL traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.db_identifier}-rds-sg" }
}

# ────────── common settings ──────────
locals {
  common_db_settings = {
    engine                 = "mysql"
    engine_version         = "8.0"
    instance_class         = var.db_instance_class
    allocated_storage      = var.db_allocated_storage
    db_subnet_group_name   = aws_db_subnet_group.default.name
    vpc_security_group_ids = [aws_security_group.rds.id]
    password               = random_password.db_master.result
    skip_final_snapshot    = true
    deletion_protection    = false
    publicly_accessible    = true
  }
}

# ────────── admin DB ──────────
resource "aws_db_instance" "admin" {
  identifier = "${var.db_identifier}-admin"
  username   = "axialy_admin"
  tags       = { Name = "${var.db_identifier}-admin" }

  for_each = { dummy = 1 } # hack to merge maps cleanly
  dynamic "apply" { for_each = [] }

  # merge common settings
  lifecycle { ignore_changes = [apply] }
  # explicit attributes so HCL stays valid
  engine                 = local.common_db_settings.engine
  engine_version         = local.common_db_settings.engine_version
  instance_class         = local.common_db_settings.instance_class
  allocated_storage      = local.common_db_settings.allocated_storage
  db_subnet_group_name   = local.common_db_settings.db_subnet_group_name
  vpc_security_group_ids = local.common_db_settings.vpc_security_group_ids
  password               = local.common_db_settings.password
  skip_final_snapshot    = local.common_db_settings.skip_final_snapshot
  deletion_protection    = local.common_db_settings.deletion_protection
  publicly_accessible    = local.common_db_settings.publicly_accessible
}

# ────────── UI DB ──────────
resource "aws_db_instance" "ui" {
  identifier = "${var.db_identifier}-ui"
  username   = "axialy_ui"
  tags       = { Name = "${var.db_identifier}-ui" }

  engine                 = local.common_db_settings.engine
  engine_version         = local.common_db_settings.engine_version
  instance_class         = local.common_db_settings.instance_class
  allocated_storage      = local.common_db_settings.allocated_storage
  db_subnet_group_name   = local.common_db_settings.db_subnet_group_name
  vpc_security_group_ids = local.common_db_settings.vpc_security_group_ids
  password               = local.common_db_settings.password
  skip_final_snapshot    = local.common_db_settings.skip_final_snapshot
  deletion_protection    = local.common_db_settings.deletion_protection
  publicly_accessible    = local.common_db_settings.publicly_accessible
}

# ────────── outputs ──────────
output "db_host"     { value = aws_db_instance.admin.address }
output "ui_db_host"  { value = aws_db_instance.ui.address }
output "db_port"     { value = aws_db_instance.admin.port }
output "db_user"     { value = aws_db_instance.admin.username }
output "db_pass" {
  value     = random_password.db_master.result
  sensitive = true
}
