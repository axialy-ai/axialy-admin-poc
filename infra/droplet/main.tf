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
#  SSH key to let you log in
# --------------------------------------------------------------------
resource "digitalocean_ssh_key" "default" {
  name       = "admin-key"
  public_key = var.ssh_public_key
}

# --------------------------------------------------------------------
#  Admin Droplet
# --------------------------------------------------------------------
resource "digitalocean_droplet" "admin" {
  name              = var.droplet_name
  region            = var.region
  size              = var.size
  image             = "ubuntu-24-04-x64"
  ssh_keys          = [digitalocean_ssh_key.default.id]

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
