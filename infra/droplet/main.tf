terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# ──────────────────────────────────────────────────────────────
#  Droplet for *any* Axialy component (admin | ui | api)
# ──────────────────────────────────────────────────────────────

resource "digitalocean_droplet" "axialy" {
  name     = var.droplet_name
  region   = var.region
  size     = var.droplet_size
  image    = "ubuntu-22-04-x64"

  ssh_keys   = [var.ssh_key_fingerprint]
  monitoring = true
  backups    = false

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    db_host                = var.db_host
    db_port                = var.db_port
    db_user                = var.db_user
    db_password            = var.db_password
    admin_default_user     = var.admin_default_user
    admin_default_email    = var.admin_default_email
    admin_default_password = var.admin_default_password

    /* NEW – pass SMTP relay creds into cloud-init */
    smtp_host              = var.smtp_host
    smtp_port              = var.smtp_port
    smtp_user              = var.smtp_user
    smtp_password          = var.smtp_password
  })

  tags = ["axialy", var.component_tag, "web"]
}

/* firewall + outputs remain exactly the same */


# ──────────────────────────────────────────────────────────────
#  Firewall for this one droplet / component
# ──────────────────────────────────────────────────────────────
resource "digitalocean_firewall" "axialy" {
  name        = "axialy-${var.component_tag}-fw-${var.droplet_name}"
  droplet_ids = [digitalocean_droplet.axialy.id]

  # SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow **all** outbound
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
#  NOTE: outputs moved to outputs.tf to avoid duplication
# ──────────────────────────────────────────────────────────────
