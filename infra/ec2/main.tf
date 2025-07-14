terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "axialy" {
  name_prefix = "${var.instance_name}-sg-"

  ingress = [
    for p in ["22","80","443"] : {
      from_port   = p
      to_port     = p
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }]
}

resource "aws_instance" "axialy" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.axialy.id]
  user_data              = base64encode(templatefile("${path.module}/cloud-init.yaml", {
                          db_host                = var.db_host
                          db_port                = var.db_port
                          db_user                = var.db_user
                          db_password            = var.db_password
                          admin_default_user     = var.admin_default_user
                          admin_default_email    = var.admin_default_email
                          admin_default_password = var.admin_default_password
                          smtp_host              = var.smtp_host
                          smtp_port              = var.smtp_port
                          smtp_user              = var.smtp_user
                          smtp_password          = var.smtp_password
                        }))

  tags = {
    Name      = var.instance_name
    Component = var.component_tag
  }
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.axialy.id
  allocation_id = var.elastic_ip_allocation_id
}

output "public_ip"  { value = aws_instance.axialy.public_ip }
output "instance_id" { value = aws_instance.axialy.id }
