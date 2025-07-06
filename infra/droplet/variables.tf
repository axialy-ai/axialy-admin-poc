variable "do_token"             { type = string; sensitive = true }
variable "ssh_fingerprint"      { type = string }
variable "droplet_name"         { type = string }
variable "region"               { type = string; default = "nyc3" }
variable "size"                 { type = string; default = "s-1vcpu-2gb" }

variable "repo_url"             { type = string }

variable "db_host"              { type = string }
variable "db_port"              { type = string }
variable "db_user"              { type = string }
variable "db_pass"              { type = string; sensitive = true }

variable "admin_default_user"      { type = string; sensitive = true }
variable "admin_default_email"     { type = string; sensitive = true }
variable "admin_default_password"  { type = string; sensitive = true }
