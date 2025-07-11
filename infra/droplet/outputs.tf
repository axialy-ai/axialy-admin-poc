/* ──────────────────────────────────────────────────────────────
 *  Canonical outputs for a single Axialy component droplet
 * ──────────────────────────────────────────────────────────── */

output "droplet_ip" {
  description = "Public IPv4 address"
  value       = digitalocean_droplet.axialy.ipv4_address
}

output "droplet_id" {
  description = "DigitalOcean droplet ID"
  value       = digitalocean_droplet.axialy.id
}

output "droplet_status" {
  description = "Current droplet status"
  value       = digitalocean_droplet.axialy.status
}

output "droplet_urn" {
  description = "Droplet URN"
  value       = digitalocean_droplet.axialy.urn
}
