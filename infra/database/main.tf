terraform {
  required_version = ">= 1.4"
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean", version = ">= 2.36.0" }
  }
}

provider "digitalocean" {
  token = var.do_token
}

############################################################
# ①  Database cluster
############################################################
resource "digitalocean_database_cluster" "axialy" {
  name       = var.db_cluster_name
  region     = var.region
  engine     = "mysql"
  version    = "8"
  size       = var.db_size
  node_count = 1
}

############################################################
# ②  Two logical databases
############################################################
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_UI"
}

############################################################
# ③  Separate users for each DB  (no password → DO generates)
############################################################
resource "digitalocean_database_user" "axialy_admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

resource "digitalocean_database_user" "axialy_ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui"
}
