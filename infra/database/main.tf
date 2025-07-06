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

/* ──────────────────────────────────────────────────────────────
 * Managed MySQL cluster for Axialy
 * ──────────────────────────────────────────────────────────── */
resource "digitalocean_database_cluster" "axialy" {
  name       = var.db_cluster_name
  region     = var.region
  engine     = "mysql"
  version    = "8"
  size       = var.db_size
  node_count = 1
}

/* ──────────────────────────────────────────────────────────────
 * Two logical DBs – **names must be lowercase** per DO rules.
 * ──────────────────────────────────────────────────────────── */
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui"
}

/* Service user (one account is enough for both DBs) */
resource "digitalocean_database_user" "axialy_admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

/* ──────────────────────────────────────────────────────────────
 *  Outputs used by the GitHub Actions workflow
 * ──────────────────────────────────────────────────────────── */
output "db_host" { value = digitalocean_database_cluster.axialy.host }
output "db_port" { value = digitalocean_database_cluster.axialy.port }
output "db_user" { value = digitalocean_database_user.axialy_admin.name }

output "db_pass" {
  value     = digitalocean_database_user.axialy_admin.password
  sensitive = true
}
