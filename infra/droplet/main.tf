################################################################################
#  infra/droplet/main.tf
#  Provisions the Axialy Admin droplet on DigitalOcean
################################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36"
    }
  }
}

# ── Provider ────────────────────────────────────────────────────────────
provider "digitalocean" {
  token = var.do_token
}

# ── Resources ───────────────────────────────────────────────────────────

# Upload (or reuse) the SSH key; satisfies the required public_key field
resource "digitalocean_ssh_key" "default" {
  name       = "axialy_admin_key"
  public_key = var.ssh_public_key
}

# Main droplet hosting Axialy Admin
resource "digitalocean_droplet" "axialy_admin" {
  name       = var.droplet_name
  region     = var.region
  size       = var.size
  image      = "ubuntu-24-04-x64"

  ssh_keys   = [digitalocean_ssh_key.default.id]

  backups    = false
  ipv6       = false
  monitoring = true

  # cloud-init script pulls repo + writes .env
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

  tags = ["axialy-admin"]
}

# ── Outputs ─────────────────────────────────────────────────────────────
output "droplet_ip" {
  description = "Public IPv4 address of the Axialy Admin droplet"
  value       = digitalocean_droplet.axialy_admin.ipv4_address
}
