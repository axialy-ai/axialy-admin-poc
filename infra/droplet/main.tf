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

# --------------------------------------------------------------------
#  Re-use the key that’s already in the DigitalOcean account
# --------------------------------------------------------------------
data "digitalocean_ssh_key" "default" {
  name = var.ssh_key_name
}

# --------------------------------------------------------------------
#  Admin Droplet
# --------------------------------------------------------------------
resource "digitalocean_droplet" "admin" {
  name     = var.droplet_name
  region   = var.region
  size     = var.size
  image    = "ubuntu-24-04-x64"
  ssh_keys = [data.digitalocean_ssh_key.default.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
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

# --------------------------------------------------------------------
#  Outputs
# --------------------------------------------------------------------
output "droplet_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}
