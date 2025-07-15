###############################
# Networking / subnet group   #
###############################

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

  tags = {
    Name = "${var.db_identifier}-subnets"
  }
}

#########################################
# Randomised master password (rotatable)#
#########################################

resource "random_password" "db_master" {
  length  = 16
  special = true
}

######################
# Security group     #
######################

resource "aws_security_group" "rds" {
  name        = "${var.db_identifier}-rds-sg"
  description = "Allow MySQL/Aurora traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL/Aurora"
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

  tags = {
    Name = "${var.db_identifier}-rds-sg"
  }
}

######################
# RDS – Admin DB     #
######################

resource "aws_db_instance" "admin" {
  identifier              = "${var.db_identifier}-admin"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  username                = "axialy_admin"
  password                = random_password.db_master.result
  skip_final_snapshot     = true
  deletion_protection     = false
  publicly_accessible     = true

  tags = {
    Name = "${var.db_identifier}-admin"
  }
}

###################
# RDS – UI DB     #
###################

resource "aws_db_instance" "ui" {
  identifier              = "${var.db_identifier}-ui"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  username                = "axialy_ui"
  password                = random_password.db_master.result
  skip_final_snapshot     = true
  deletion_protection     = false
  publicly_accessible     = true

  tags = {
    Name = "${var.db_identifier}-ui"
  }
}

################
#   OUTPUTS    #
################

output "db_host" {
  description = "Primary endpoint for the Admin DB"
  value       = aws_db_instance.admin.address
}

output "ui_db_host" {
  description = "Primary endpoint for the UI DB"
  value       = aws_db_instance.ui.address
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
