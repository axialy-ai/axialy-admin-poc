############################
# Networking prerequisites #
############################

locals {
  use_default_vpc = length(trimspace(var.vpc_id)) == 0
}

# Either grab the default VPC or the one supplied as a variable
data "aws_vpc" "selected" {
  count = local.use_default_vpc ? 1 : 0
  default = true
}

data "aws_vpc" "override" {
  count = local.use_default_vpc ? 0 : 1
  id    = var.vpc_id
}

locals {
  vpc_id = local.use_default_vpc ? data.aws_vpc.selected[0].id : data.aws_vpc.override[0].id
}

data "aws_subnet_ids" "selected" {
  vpc_id = local.vpc_id
}

########################
# Security group rules #
########################

resource "aws_security_group" "admin" {
  name        = "${var.instance_name}-sg"
  description = "Allow SSH & HTTP/S for Axialy Admin"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.instance_name}-sg"
  }
}

##################
# EC2 – instance #
##################

resource "aws_instance" "admin" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnet_ids.selected.ids, 0)
  vpc_security_group_ids      = [aws_security_group.admin.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#######################
# Elastic-IP binding  #
#######################

resource "aws_eip_association" "this" {
  allocation_id = var.elastic_ip_allocation_id
  instance_id   = aws_instance.admin.id
}

################
#    OUTPUTS   #
################

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.admin.public_ip
}

output "instance_id" {
  value = aws_instance.admin.id
}
