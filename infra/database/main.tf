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
 *  Managed MySQL cluster for Axialy
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
 *  Logical databases (names must be lower-case)
 * ──────────────────────────────────────────────────────────── */
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui"
  # Ensure this runs after the admin DB to avoid
  # two concurrent DB-create calls on a brand-new cluster.
  depends_on = [digitalocean_database_db.admin]
}

/* ──────────────────────────────────────────────────────────────
 *  Service user – created **after** both DBs exist so that
 *  it inherits privileges on **both** databases.
 * ──────────────────────────────────────────────────────────── */
resource "digitalocean_database_user" "axialy_admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
  depends_on = [
    digitalocean_database_db.admin,
    digitalocean_database_db.ui
  ]
}

# OUTPUTS ARE NOW IN outputs.tf FILE - DO NOT DUPLICATE HERE
