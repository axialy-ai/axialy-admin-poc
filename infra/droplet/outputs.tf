output "droplet_ip" {
  description = "Public IPv4 address of the Admin droplet"
  value       = digitalocean_droplet.admin.ipv4_address
}
