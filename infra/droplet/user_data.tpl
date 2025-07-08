#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx
  - php-fpm
  - php-mysql
  - php-mbstring
  - php-xml
  - php-zip
  - php-curl
  - git
  - unzip
  - mariadb-client

write_files:
  # ───────── nginx vhost ─────────
  - path: /etc/nginx/sites-available/axialy_admin
    permissions: "0644"
    content: |
      server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        root /var/www/axialy-admin;                # ← new — no sub-folder
        index index.php index.html;

        client_max_body_size 50M;

        location / {
          try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
          include snippets/fastcgi-php.conf;
          fastcgi_pass unix:/run/php/php8.3-fpm.sock;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          include fastcgi_params;
        }

        location ~ /\. { deny all; }
        location ~ /\.env { deny all; }
      }

  # ───────── runtime secrets (.env) ─────────
  - path: /tmp/axialy-admin.env
    permissions: "0600"
    content: |
      DB_HOST=${db_host}
      DB_PORT=${db_port}
      DB_NAME=axialy_admin
      DB_USER=${db_user}
      DB_PASSWORD=${db_pass}

      UI_DB_HOST=${db_host}
      UI_DB_PORT=${db_port}
      UI_DB_NAME=axialy_ui
      UI_DB_USER=${db_user}
      UI_DB_PASSWORD=${db_pass}

      ADMIN_DEFAULT_USER=${admin_default_user}
      ADMIN_DEFAULT_EMAIL=${admin_default_email}
      ADMIN_DEFAULT_PASSWORD=${admin_default_password}

runcmd:
  # 1. web root
  - mkdir -p /var/www/axialy-admin
  - chown -R www-data:www-data /var/www

  # 2. get the code directly *into* the web root
  - git clone --depth 1 ${repo_url} /var/www/axialy-admin

  # 3. drop .env
  - mv /tmp/axialy-admin.env /var/www/axialy-admin/.env
  - chown www-data:www-data /var/www/axialy-admin/.env
  - chmod 600 /var/www/axialy-admin/.env

  # 4. perms
  - chown -R www-data:www-data /var/www/axialy-admin
  - find  /var/www/axialy-admin -type d -exec chmod 755 {} \;
  - find  /var/www/axialy-admin -type f -exec chmod 644 {} \;

  # 5. enable vhost
  - ln -sf /etc/nginx/sites-available/axialy_admin /etc/nginx/sites-enabled/
  - rm -f  /etc/nginx/sites-enabled/default
  - systemctl restart php8.3-fpm nginx

  # 6. wait for DB & import schemas *once*
  - |
    for i in {1..30}; do
      if mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} -e "SELECT 1" &>/dev/null; then
        break
      fi
      sleep 5
    done
  - |
    if ! mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_admin \
         -e "SHOW TABLES LIKE 'admin_users'" | grep -q admin_users; then
      mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_admin \
        < /var/www/axialy-admin/db/axialy_admin.sql
    fi
  - |
    if ! mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_ui \
         -e "SHOW TABLES LIKE 'ui_users'" | grep -q ui_users; then
      mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_ui \
        < /var/www/axialy-admin/db/axialy_ui.sql
    fi
