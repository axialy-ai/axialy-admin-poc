#cloud-config
packages:
  - nginx
  - php-fpm
  - php-mysql
  - mysql-client
  - git

runcmd:
  - systemctl enable --now nginx php8.3-fpm
  - useradd -m -s /bin/bash axialy || true

  # ------------------------------------------------------------------
  # 1. Clone the repository to /home/axialy/axialy
  # ------------------------------------------------------------------
  - sudo -u axialy git clone --depth 1 ${repo_url} /home/axialy/axialy

  # 2. Expose the Admin product at /var/www/axialy
  - ln -snf /home/axialy/axialy/axialy-admin-product /var/www/axialy

  # ------------------------------------------------------------------
  # 3. Write .env so PHP can read DB creds & default-admin seed values
  # ------------------------------------------------------------------
  - |
    cat >/var/www/axialy/.env <<EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=axialy_admin
DB_USER=${db_user}
DB_PASSWORD="${db_pass}"

UI_DB_HOST=${db_host}
UI_DB_PORT=${db_port}
UI_DB_NAME=axialy_ui
UI_DB_USER=${db_user}
UI_DB_PASSWORD="${db_pass}"

ADMIN_DEFAULT_USER=${admin_default_user}
ADMIN_DEFAULT_EMAIL=${admin_default_email}
ADMIN_DEFAULT_PASSWORD=${admin_default_password}
EOF

  # Nginx: serve index.php by default
  - sed -i 's/index index.html/index index.php/' /etc/nginx/sites-enabled/default
  - systemctl reload nginx

  # ------------------------------------------------------------------
  # 4. Import both SQL schema dumps into the freshly created cluster
  # ------------------------------------------------------------------
  - |
    echo "Importing Axialy schema …"
    mysql -h ${db_host} -P ${db_port} -u ${db_user} -p"${db_pass}" axialy_admin < /home/axialy/axialy/db/axialy_admin.sql
    mysql -h ${db_host} -P ${db_port} -u ${db_user} -p"${db_pass}" axialy_ui    < /home/axialy/axialy/db/axialy_ui.sql
    echo "Schema import complete."
