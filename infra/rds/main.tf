# infra/rds/main.tf

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region
}

# Ask AWS for the default VPC in this account/region
data "aws_vpc" "default" {
  default = true
}

# Retrieve the default subnets that belong to that VPC (for the subnet group)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.instance_name}-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.instance_name}-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.instance_name}-sg"
  description = "Allow inbound DB traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

resource "random_password" "db" {
  length  = 16
  special = false
}

resource "aws_db_instance" "admin" {
  identifier              = var.instance_name
  engine                  = "postgres"
  engine_version          = "16.2"
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = random_password.db.result
  port                    = var.db_port
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = true
  skip_final_snapshot     = true
  deletion_protection     = false
  allocated_storage       = 20
  storage_type            = "gp3"

  tags = {
    Name = var.instance_name
  }
}

output "db_endpoint" {
  value = aws_db_instance.admin.address
}
