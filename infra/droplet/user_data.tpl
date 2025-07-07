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
  # .env consumed by the PHP app
  - path: /tmp/axialy-admin.env
    permissions: '0600'
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

  # Nginx configuration
  - path: /etc/nginx/sites-available/axialy_admin
    permissions: '0644'
    content: |
      server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        
        root /var/www/axialy-admin/axialy-admin-product;
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
        
        location ~ /\.ht {
          deny all;
        }
        
        location ~ /\.env {
          deny all;
        }
      }

  # Deployment script
  - path: /usr/local/bin/deploy_axialy_admin.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      
      echo "Starting Axialy Admin deployment..."
      
      # Create web directory
      install -d -o www-data -g www-data /var/www/axialy-admin
      
      # Clone or update repository
      if [ ! -d /var/www/axialy-admin/.git ]; then
        echo "Cloning repository..."
        git clone --depth 1 ${repo_url} /var/www/axialy-admin
      else
        echo "Updating repository..."
        cd /var/www/axialy-admin && git pull --ff-only
      fi
      
      # Move .env file to proper location
      if [ -f /tmp/axialy-admin.env ]; then
        mv /tmp/axialy-admin.env /var/www/axialy-admin/axialy-admin-product/.env
        chown www-data:www-data /var/www/axialy-admin/axialy-admin-product/.env
        chmod 600 /var/www/axialy-admin/axialy-admin-product/.env
      fi
      
      # Set proper permissions
      chown -R www-data:www-data /var/www/axialy-admin
      find /var/www/axialy-admin -type d -exec chmod 755 {} \;
      find /var/www/axialy-admin -type f -exec chmod 644 {} \;
      
      # Configure PHP-FPM
      PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
      sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/$PHP_VERSION/fpm/php.ini
      
      # Enable and configure nginx
      ln -sf /etc/nginx/sites-available/axialy_admin /etc/nginx/sites-enabled/
      rm -f /etc/nginx/sites-enabled/default
      
      # Test nginx configuration
      nginx -t
      
      # Restart services
      systemctl restart php$PHP_VERSION-fpm
      systemctl restart nginx
      
      # Wait for database to be ready
      echo "Waiting for database connection..."
      for i in {1..30}; do
        if mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} -e "SELECT 1" &>/dev/null; then
          echo "Database connection successful!"
          break
        fi
        echo "Waiting for database... ($i/30)"
        sleep 5
      done
      
      # Import database schemas if they don't exist
      echo "Checking database schemas..."
      if ! mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_admin -e "SHOW TABLES LIKE 'admin_users'" | grep -q admin_users; then
        echo "Importing Axialy Admin schema..."
        mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_admin < /var/www/axialy-admin/db/axialy_admin.sql
      fi
      
      if ! mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_ui -e "SHOW TABLES LIKE 'ui_users'" | grep -q ui_users; then
        echo "Importing Axialy UI schema..."
        mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_pass} axialy_ui < /var/www/axialy-admin/db/axialy_ui.sql
      fi
      
      echo "Axialy Admin deployment completed!"

runcmd:
  - systemctl enable nginx
  - systemctl enable php8.3-fpm
  - bash /usr/local/bin/deploy_axialy_admin.sh

final_message: |
  ✅ Axialy Admin deployed successfully!
  Access the application at http://<droplet-ip>/
  Initial setup: use 'Casellio' as the admin code when prompted.
