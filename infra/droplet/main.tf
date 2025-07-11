terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36"
    }
    random = {                       # NEW – for unique firewall names
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# ──────────────────────────────────────────────────────────────
# Droplet
# ──────────────────────────────────────────────────────────────
resource "digitalocean_droplet" "this" {
  name   = var.droplet_name
  region = var.region
  size   = var.droplet_size
  image  = "ubuntu-22-04-x64"

  ssh_keys  = [var.ssh_key_fingerprint]
  monitoring = true
  backups    = false

  # Optional – lets the UI & API re-use the module while running
  # their own Ansible/GitHub-Actions bootstrap instead of cloud-init
  dynamic "user_data" {
    for_each = var.skip_cloud_init ? [] : [1]
    content  = templatefile("${path.module}/cloud-init.yaml", {
      db_host                = var.db_host
      db_port                = var.db_port
      db_user                = var.db_user
      db_password            = var.db_password
      admin_default_user     = var.admin_default_user
      admin_default_email    = var.admin_default_email
      admin_default_password = var.admin_default_password
    })
  }

  tags = ["axialy", "admin", "web"]
}

# ──────────────────────────────────────────────────────────────
# Firewall – name guaranteed unique per run
# ──────────────────────────────────────────────────────────────
resource "digitalocean_firewall" "this" {
  name = "axialy-admin-${random_id.fw.hex}"

  droplet_ids = [digitalocean_droplet.this.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# ──────────────────────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────────────────────
output "droplet_ip"     { value = digitalocean_droplet.this.ipv4_address }
output "droplet_id"     { value = digitalocean_droplet.this.id }
output "droplet_status" { value = digitalocean_droplet.this.status }
output "droplet_urn"    { value = digitalocean_droplet.this.urn }
output "firewall_name"  { value = digitalocean_firewall.this.name }
