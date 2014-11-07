#!/usr/bin/env bash

# Define script usage
read -r -d '' USAGE <<-'EOF'
Creates an Nginx site configuration file.

Usage: cakebox-site [NAME] [ROOT]

    NAME: fqdn of the site (e.g. app.dev)
    ROOT: full path to site root (e.g. /var/www/app.dev/app/webroot)
EOF

# Check required parameters
if [[ -z "$1" || -z "$2" ]]
  then
    printf "\n$USAGE\n\nError: missing required parameter.\n\n"
    exit 1
fi

# Vagrant provisioning feedback
echo "Creating Nginx site configuration file for $1"

# Generate Nginx site configuration file
block="
server {
  listen 80;
  server_name $1;
  root $2;
  index index.php index.htm index.html;

  access_log /var/log/nginx/$1.access.log;
  error_log /var/log/nginx/$1.error.log;

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php\$ {
    try_files \$uri = 404;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_intercept_errors on;

  }

  # deny access to hidden
  location ~ /\. {
          deny all;
  }
}
"

# Create Nginx site configuration file
#echo "$block" | sudo tee "/etc/nginx/sites-available/$1" > /dev/null
echo "$block" > "/etc/nginx/sites-available/$1"

# Use nxesnite to:
# - validate file syntax
# - create the symbolic link in /etc/nginx/sites-enabled
nxensite $1

# Reload Nginx to enable new site
service nginx reload
