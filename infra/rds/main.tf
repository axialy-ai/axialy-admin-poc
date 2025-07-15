############################################
# Data sources – default VPC & its subnets #
############################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################################
# Security group for the Postgres cluster  #
############################################
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PostgreSQL"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# Subnet group & random DB password        #
############################################
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

############################################
# PostgreSQL instance                      #
############################################
resource "aws_db_instance" "admin" {
  identifier             = "axialy-admin"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"

  username               = var.db_user
  password               = random_password.db_password.result
  port                   = var.db_port

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name

  skip_final_snapshot    = true
}
