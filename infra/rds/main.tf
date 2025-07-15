data "aws_vpc" "default" {
  default = true          # ← asks AWS for the account/region’s default VPC
}

resource "aws_security_group" "rds" {
  name        = "${var.db_identifier}-rds-sg"
  description = "Allow MySQL traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MySQL"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.db_identifier}-rds-sg" }
}
