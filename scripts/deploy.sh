#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Axialy Admin droplet bootstrap
###############################################################################

echo "▶ Waiting for apt/dpkg locks"
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
   || sudo fuser /var/lib/apt/lists/lock      >/dev/null 2>&1; do
  printf '.'
  sleep 2
done
echo " ok"

echo "▶ Updating package lists"
sudo apt-get update -qq

echo "▶ Installing nginx + PHP-FPM + extensions"
install_cmd="sudo DEBIAN_FRONTEND=noninteractive \
  apt-get install -y nginx php8.1-fpm php8.1-mysql \
                     php8.1-mbstring php8.1-xml php8.1-curl \
                     php8.1-zip php8.1-gd"
if ! eval "$install_cmd"; then
  echo "⟳ apt was still busy — retrying in 5 s"
  sleep 5
  eval "$install_cmd"
fi

echo "▶ Hardening PHP"
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.1/fpm/php.ini

echo "▶ Writing nginx vhost"
sudo tee /etc/nginx/sites-available/axialy-admin.conf >/dev/null <<'NGINX'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  root /var/www/axialy-admin;
  index index.php;

  location / {
    try_files $uri $uri/ /index.php?$query_string;
  }

  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.1-fpm.sock;
  }

  location ~ /\. { deny all; }

  add_header X-Frame-Options SAMEORIGIN;
  add_header X-Content-Type-Options nosniff;
}
NGINX
sudo ln -sf /etc/nginx/sites-available/axialy-admin.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

echo "▶ Enabling & starting services"
sudo systemctl enable php8.1-fpm nginx
sudo systemctl restart php8.1-fpm
sudo nginx -t
sudo systemctl restart nginx

echo "▶ Syncing application code"
sudo mkdir -p /var/www/axialy-admin
sudo tar -xzf /tmp/axialy-admin.tar.gz -C /var/www/axialy-admin
sudo chown -R www-data:www-data /var/www/axialy-admin
sudo find /var/www/axialy-admin -type d -exec chmod 755 {} \;
sudo find /var/www/axialy-admin -type f -exec chmod 644 {} \;

echo "▶ Writing .env"
sudo tee /var/www/axialy-admin/.env >/dev/null <<ENV
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=axialy_admin
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

UI_DB_HOST=${DB_HOST}
UI_DB_PORT=${DB_PORT}
UI_DB_NAME=axialy_ui
UI_DB_USER=${DB_USER}
UI_DB_PASSWORD=${DB_PASSWORD}

ADMIN_DEFAULT_USER=${ADMIN_DEFAULT_USER}
ADMIN_DEFAULT_EMAIL=${ADMIN_DEFAULT_EMAIL}
ADMIN_DEFAULT_PASSWORD=${ADMIN_DEFAULT_PASSWORD}
ENV
sudo chown  www-data:www-data /var/www/axialy-admin/.env
sudo chmod 640              /var/www/axialy-admin/.env

echo "▶ Final nginx reload"
sudo systemctl reload nginx
echo "✅ Deployment script finished."
