# Generate random passwords for database users
resource "random_password" "db_admin_password" {
  length  = 16
  special = true
}

resource "random_password" "db_ui_password" {
  length  = 16
  special = true
}

# Create the database cluster
resource "digitalocean_database_cluster" "axialy_mysql" {
  name       = "axialy-mysql-cluster"
  engine     = "mysql"
  version    = "8"
  size       = var.db_cluster_size
  region     = var.region
  node_count = 1

  lifecycle {
    prevent_destroy = false
  }
}

# Create databases
resource "digitalocean_database_db" "axialy_admin" {
  cluster_id = digitalocean_database_cluster.axialy_mysql.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "axialy_ui" {
  cluster_id = digitalocean_database_cluster.axialy_mysql.id
  name       = "Axialy_UI"
}

# Create database users
resource "digitalocean_database_user" "admin_user" {
  cluster_id = digitalocean_database_cluster.axialy_mysql.id
  name       = "axialy_admin_user"
}

resource "digitalocean_database_user" "ui_user" {
  cluster_id = digitalocean_database_cluster.axialy_mysql.id
  name       = "axialy_ui_user"
}

# Create the droplet
resource "digitalocean_droplet" "axialy_admin" {
  name     = "axialy-admin-app"
  region   = var.region
  size     = var.droplet_size
  image    = "ubuntu-22-04-x64"
  ssh_keys = [var.ssh_fingerprint]

  lifecycle {
    create_before_destroy = true
  }
}

# Create firewall for the droplet
resource "digitalocean_firewall" "axialy_admin" {
  name = "axialy-admin-firewall"

  droplet_ids = [digitalocean_droplet.axialy_admin.id]

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

# Add droplet to database firewall
resource "digitalocean_database_firewall" "axialy_mysql_fw" {
  cluster_id = digitalocean_database_cluster.axialy_mysql.id

  rule {
    type  = "droplet"
    value = digitalocean_droplet.axialy_admin.id
  }
}
