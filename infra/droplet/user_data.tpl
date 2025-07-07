#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
  - php-fpm
  - php-mysql
  - git
  - unzip

write_files:
  # ── .env for the PHP app ─────────────────────────────────────────────
  - path: /var/www/axialy-admin/.env
    owner: www-data:www-data
    permissions: '0600'
    content: |
      DB_HOST=${db_host}
      DB_PORT=${db_port}
      DB_NAME=Axialy_ADMIN
      DB_USER=${db_user}
      DB_PASSWORD=${db_pass}

      UI_DB_HOST=${db_host}
      UI_DB_PORT=${db_port}
      UI_DB_NAME=Axialy_UI
      UI_DB_USER=${db_user}
      UI_DB_PASSWORD=${db_pass}

      ADMIN_DEFAULT_USER=${admin_default_user}
      ADMIN_DEFAULT_EMAIL=${admin_default_email}
      ADMIN_DEFAULT_PASSWORD=${admin_default_password}

  # ── bootstrap script ────────────────────────────────────────────────
  - path: /usr/local/bin/deploy_axialy_admin.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail

      # 1) clone or pull repo
      install -d -o www-data -g www-data /var/www/axialy-admin
      if [ ! -d /var/www/axialy-admin/.git ]; then
        sudo -u www-data git clone --depth 1 ${repo_url} /var/www/axialy-admin
      else
        sudo -u www-data git -C /var/www/axialy-admin pull
      fi

      # 2) vhost
      cat >/etc/nginx/sites-available/axialy_admin <<'NGINX'
      server {
        listen 80 default_server;
        server_name _;
        root /var/www/axialy-admin/axialy-admin-product;
        index index.php index.html;

        location / {
          try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
          include snippets/fastcgi-php.conf;
          fastcgi_pass unix:/run/php/php-fpm.sock;
        }
      }
      NGINX

      ln -sf /etc/nginx/sites-available/axialy_admin /etc/nginx/sites-enabled/axialy_admin
      rm -f  /etc/nginx/sites-enabled/default
      systemctl enable --now nginx

runcmd:
  - [ bash, /usr/local/bin/deploy_axialy_admin.sh ]
