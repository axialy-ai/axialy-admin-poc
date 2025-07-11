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
