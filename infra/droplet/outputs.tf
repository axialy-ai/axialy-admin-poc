/* ──────────────────────────────────────────────────────────────
 *  Outputs for the Axialy Admin droplet
 * ──────────────────────────────────────────────────────────── */

output "droplet_ip" {
  description = "Public IP address of the Axialy Admin droplet"
  value       = digitalocean_droplet.axialy_admin.ipv4_address
}

output "droplet_id" {
  description = "ID of the Axialy Admin droplet"
  value       = digitalocean_droplet.axialy_admin.id
}

output "droplet_status" {
  description = "Status of the droplet"
  value       = digitalocean_droplet.axialy_admin.status
}

output "droplet_urn" {
  description = "URN of the droplet"
  value       = digitalocean_droplet.axialy_admin.urn
}
