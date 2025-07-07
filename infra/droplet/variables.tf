variable "do_token"              { type = string }

# Fingerprint of the **existing** SSH key in DigitalOcean
variable "ssh_fingerprint"       { type = string }

variable "droplet_name"          { type = string }
variable "region"                { type = string }
variable "size"                  { type = string }

variable "repo_url"              { type = string }

variable "db_host"               { type = string }
variable "db_port"               { type = string }
variable "db_user"               { type = string }
variable "db_pass"               { type = string }

variable "admin_default_user"    { type = string }
variable "admin_default_email"   { type = string }
variable "admin_default_password"{ type = string }
