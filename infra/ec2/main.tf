# ────────── networking ──────────
data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ────────── security group ──────────
resource "aws_security_group" "admin" {
  name        = "${var.instance_name}-sg"
  description = "Allow SSH/HTTP/HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress { from_port = 22  to_port = 22  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] description = "SSH"   }
  ingress { from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] description = "HTTP"  }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] description = "HTTPS" }

  egress  { from_port = 0   to_port = 0   protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = { Name = "${var.instance_name}-sg" }
}

# ────────── EC2 instance ──────────
data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]        # Canonical
  most_recent = true
  filter { name = "name" values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-24.04-amd64-server-*"] }
}

resource "aws_instance" "admin" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.admin.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = { Name = var.instance_name }
}

# ────────── Elastic-IP binding ──────────
resource "aws_eip_association" "this" {
  allocation_id = var.elastic_ip_allocation_id
  instance_id   = aws_instance.admin.id
}

output "instance_public_ip" { value = aws_instance.admin.public_ip }
