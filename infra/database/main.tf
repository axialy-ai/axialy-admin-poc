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

/* ──────────────────────────────────────────────────────────
 * 1 × managed MySQL cluster
 * ────────────────────────────────────────────────────────── */
resource "digitalocean_database_cluster" "axialy" {
  name       = var.db_cluster_name
  region     = var.region
  engine     = "mysql"
  version    = "8"
  size       = var.db_size
  node_count = 1
}

/* Logical DBs inside the cluster */
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_UI"
}

/* Service user – DO autogenerates a strong password for us */
resource "digitalocean_database_user" "axialy_admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

/* ──────────────────────────────────────────────────────────
 * Outputs consumed by the GH workflow (become repo secrets)
 * ────────────────────────────────────────────────────────── */
output "db_host" { value = digitalocean_database_cluster.axialy.host }

output "db_port" { value = digitalocean_database_cluster.axialy.port }

output "db_user" { value = digitalocean_database_user.axialy_admin.name }

output "db_pass" {
  value     = digitalocean_database_user.axialy_admin.password
  sensitive = true
}
