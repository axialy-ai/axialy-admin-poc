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
  - path: /etc/environment
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

      export DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD
      export UI_DB_HOST UI_DB_PORT UI_DB_NAME UI_DB_USER UI_DB_PASSWORD
      export ADMIN_DEFAULT_USER ADMIN_DEFAULT_EMAIL ADMIN_DEFAULT_PASSWORD

  - path: /usr/local/bin/deploy_axialy_admin.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail

      #----- 1) Clone repo ---------------------------------------------------
      mkdir -p /var/www/axialy-admin
      chown -R www-data:www-data /var/www/axialy-admin
      if [ ! -d /var/www/axialy-admin/.git ]; then
        sudo -u www-data git clone --depth 1 ${repo_url} /var/www/axialy-admin
      else
        sudo -u www-data git -C /var/www/axialy-admin pull
      fi

      #----- 2) Project-level .env (read by AdminDBConfig & ui_db_connection) -
      cat >/var/www/axialy-admin/.env <<EOF
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
EOF
      chown www-data:www-data /var/www/axialy-admin/.env
      chmod 600 /var/www/axialy-admin/.env

      #----- 3) Nginx virtual-host ------------------------------------------
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
      rm -f /etc/nginx/sites-enabled/default

      systemctl reload nginx
      echo "Axialy Admin deployed."
runcmd:
  - [ bash, /usr/local/bin/deploy_axialy_admin.sh ]
