#!/usr/bin/env bash
#
# deploy.sh – runs on the droplet via ssh
#
# Responsibilities
#   • Installs/updates nginx + PHP, retrying sanely on apt locks
#   • Unpacks /tmp/axialy-admin.tar.gz → /var/www/axialy-admin
#   • Creates an nginx vhost (if missing) and reloads services
#
# This script is idempotent and will exit non-zero on any failure.
#

set -euo pipefail

# -----------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------
wait_for_apt() {
  # Block until no dpkg/apt process or lock file is active
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
     || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 \
     || pgrep -x apt >/dev/null \
     || pgrep -x dpkg >/dev/null; do
    echo "⟳ apt is busy – sleeping 5 s"
    sleep 5
  done
}

retry_apt() {
  local tries=0 max=12   # 12 × 5 s = 60 s
  until DEBIAN_FRONTEND=noninteractive \
        apt-get -o DPkg::Lock::Timeout=30 "$@"; do
    (( ++tries == max )) && {
      echo "❌ apt is still locked after $((tries*5)) s – aborting"; exit 1; }
    echo "⟳ apt locked – retrying ($tries/$max)"
    sleep 5
  done
}

# -----------------------------------------------------------------------
# System packages (nginx + PHP)
# -----------------------------------------------------------------------
wait_for_apt
retry_apt update -qq
wait_for_apt            # unattended-upgrade often kicks in here
retry_apt install -y \
    nginx \
    php8.1-fpm \
    php8.1-{mysql,mbstring,xml,curl,zip,gd}

systemctl enable --now nginx php8.1-fpm

# -----------------------------------------------------------------------
# Application code
# -----------------------------------------------------------------------
APP_DIR="/var/www/axialy-admin"
mkdir -p "$APP_DIR"
tar -xzf /tmp/axialy-admin.tar.gz -C "$APP_DIR" --strip-components=1
chown -R www-data:www-data "$APP_DIR"

# -----------------------------------------------------------------------
# Nginx vhost
# -----------------------------------------------------------------------
VHOST="/etc/nginx/sites-available/axialy-admin.conf"
if [[ ! -f $VHOST ]]; then
cat > "$VHOST" <<'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/axialy-admin/public;

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg)$ {
        expires 30d;
        access_log off;
    }
}
NGINX
    ln -s "$VHOST" /etc/nginx/sites-enabled/axialy-admin.conf
fi

nginx -t
systemctl reload nginx

echo "✅ Deployment finished"
