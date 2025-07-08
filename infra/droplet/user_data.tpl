#cloud-config
#
#  Axialy admin / UI – droplet bootstrap
#  ------------------------------------------------------------
#  • Installs the *matching* PHP-FPM version
#  • Drops an nginx vhost that uses that socket
#  • Enables & starts everything
#
write_files:
  - path: /etc/apt/apt.conf.d/99noninteractive
    permissions: "0644"
    content: |
      APT::Get::Assume-Yes "true";
      APT::Get::Force-Yes "true";
      DPkg::Options {
        "--force-confdef";
        "--force-confold";
      }

  - path: /etc/nginx/sites-available/axialy-admin.conf
    permissions: "0644"
    content: |
      server {
          listen 80 default_server;
          listen [::]:80 default_server;
          server_name _;
          root /var/www/axialy-admin;

          index index.php;
          client_max_body_size 16M;

          location / {
              try_files $uri $uri/ /index.php?$query_string;
          }

          location ~ \.php$ {
              include               fastcgi_params;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              fastcgi_pass          unix:/run/php/php8.3-fpm.sock;
          }

          location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
              expires 30d;
              access_log off;
          }
      }

runcmd:
  # 1. base system + php-fpm
  - |
    apt update
    apt install nginx php8.3-fpm php8.3-mysql

  # 2. enable vhost
  - |
    ln -sf /etc/nginx/sites-available/axialy-admin.conf \
          /etc/nginx/sites-enabled/axialy-admin.conf
    rm -f /etc/nginx/sites-enabled/default

  # 3. make sure the socket directory exists on boot
  - |
    systemctl enable php8.3-fpm
    systemctl enable nginx
    systemctl restart php8.3-fpm
    nginx -t
    systemctl restart nginx
