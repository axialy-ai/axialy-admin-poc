terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.4"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "deployer" {
  fingerprint = var.ssh_fingerprint
}

resource "digitalocean_droplet" "admin" {
  name   = var.droplet_name
  image  = "ubuntu-24-04-x64"
  region = var.region
  size   = var.size
  ssh_keys = [
    data.digitalocean_ssh_key.deployer.id
  ]

  /* cloud-init sets up Nginx, PHP, clones the repo and writes .env */
  user_data = templatefile("${path.module}/cloud-init.tpl", {
    repo_url               = var.repo_url
    db_host                = var.db_host
    db_port                = var.db_port
    db_user                = var.db_user
    db_pass                = var.db_pass
    admin_default_user     = var.admin_default_user
    admin_default_email    = var.admin_default_email
    admin_default_password = var.admin_default_password
  })
}

output "droplet_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}
