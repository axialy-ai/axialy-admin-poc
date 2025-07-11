/* ──────────────────────────────────────────────────────────────
 *  Outputs for whichever Axialy component this droplet hosts
 * ──────────────────────────────────────────────────────────── */

output "droplet_ip"     { value = digitalocean_droplet.axialy.ipv4_address }
output "droplet_id"     { value = digitalocean_droplet.axialy.id }
output "droplet_status" { value = digitalocean_droplet.axialy.status }
output "droplet_urn"    { value = digitalocean_droplet.axialy.urn }
