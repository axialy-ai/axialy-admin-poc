###############################################################################
# Terraform configuration
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36.0"
    }
  }
}

###############################################################################
# Variables
###############################################################################

variable "droplet_name"            { type = string }
variable "region"                  { type = string }
variable "size"                    { type = string }
variable "repo_url"                { type = string }
variable "ssh_public_key"          { type = string }
variable "db_host"                 { type = string }
variable "db_port"                 { type = number }
variable "db_user"                 { type = string }
variable "db_pass"                 { type = string }
variable "admin_default_user"      { type = string }
variable "admin_default_email"     { type = string }
variable "admin_default_password"  { type = string }

###############################################################################
# Render cloud-init template in-memory (no file lookup at runtime)
###############################################################################

data "templatefile" "user_data" {
  template = file("${path.module}/cloud-init.tftpl")

  vars = {
    repo_url               = var.repo_url
    db_host                = var.db_host
    db_port                = var.db_port
    db_user                = var.db_user
    db_pass                = var.db_pass
    admin_default_user     = var.admin_default_user
    admin_default_email    = var.admin_default_email
    admin_default_password = var.admin_default_password
  }
}

###############################################################################
# DigitalOcean resources
###############################################################################

resource "digitalocean_ssh_key" "default" {
  name       = "${var.droplet_name}-key"
  public_key = var.ssh_public_key
}

resource "digitalocean_droplet" "admin" {
  name              = var.droplet_name
  region            = var.region
  size              = var.size
  image             = "ubuntu-24-04-x64"
  ssh_keys          = [digitalocean_ssh_key.default.id]
  user_data         = data.templatefile.user_data.rendered
  monitoring        = true
  backups           = false
  ipv6              = true
  private_networking = true
}

output "droplet_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}
