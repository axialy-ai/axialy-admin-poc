terraform {
  required_version = ">= 1.6.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Data source to get the SSH key
data "digitalocean_ssh_key" "this" {
  name = var.ssh_key_name
}

# The Axialy Admin droplet
resource "digitalocean_droplet" "admin" {
  name   = var.droplet_name
  region = var.region
  size   = var.size
  image  = "ubuntu-24-04-x64"
  
  ssh_keys   = [data.digitalocean_ssh_key.this.id]
  ipv6       = false
  monitoring = true
  backups    = false
  
  # Use the template file to generate user_data
  user_data = templatefile("${path.module}/user_data.tpl", {
    repo_url               = var.repo_url
    db_host                = var.db_host
    db_port                = var.db_port
    db_user                = var.db_user
    db_pass                = var.db_pass
    admin_default_user     = var.admin_default_user
    admin_default_email    = var.admin_default_email
    admin_default_password = var.admin_default_password
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
