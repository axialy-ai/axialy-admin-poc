/* … provider + terraform blocks stay unchanged … */

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
