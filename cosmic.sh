# used
web_configure(){
  if [ "$webs_choice" = "1" ]; then
    configure_nginx
  fi
}

setup_cosmic(){
  # Clone into cosmic
  if ! [ -d "/var/www" ]; then
    mkdir /var/www
  fi

  git clone https://git.krews.org/Raizer/cosmic-assets.git

  mv cosmic-assets/Plugin/Webkit.jar ./

  cd /var/www/

  git clone https://git.krews.org/Raizer/Cosmic.git

  mkdir $CMS_DOMAIN

  mv Cosmic/* $CMS_DOMAIN

  sudo chown -R $USER:www-data /var/www/$CMS_DOMAIN

  rm -rf Cosmic

  cd $CMS_DOMAIN

  composer install

  curl -o /var/www/$CMS_DOMAIN/.env $GITHUB_URL/nginx/cosmic/.env

  sed -i -e "s|DB_NAME=cosmic|DB_NAME=${DB_DATABASE}|g" /var/www/$CMS_DOMAIN/.env

  sed -i -e "s|DB_USER=raizer|DB_USER=${DB_USERNAME}|g" /var/www/$CMS_DOMAIN/.env

  sed -i -e "s|DB_PASS=meteor123|DB_PASS=${DB_PASSWORD}|g" /var/www/$CMS_DOMAIN/.env

}

# used
register_cms_hosts(){
bash -c "cat >> /etc/hosts" << EOF
127.0.0.1         $CMS_DOMAIN
EOF
}

# used
configure_nginx(){
  output "********************************************************"
  output "Configure Cosmic Web Server..."
  output "********************************************************"

  # Enable and start Nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx

  if [[ "$answer" =~ [Yy] ]]; then
    curl -o /etc/nginx/sites-available/$CMS_DOMAIN $GITHUB_URL/nginx/cosmic/nginx.conf
    cloudflare
  else
    curl -o /etc/nginx/sites-available/$CMS_DOMAIN $GITHUB_URL/nginx/cosmic/nginx.conf
  fi

  sed -i -e "s|DOMAIN|$CMS_DOMAIN|g" /etc/nginx/sites-available/$CMS_DOMAIN

  # Create link to sites-enabled
  sudo ln -s /etc/nginx/sites-available/$CMS_DOMAIN /etc/nginx/sites-enabled/

  sudo rm /etc/nginx/sites-enabled/default

  # Register hosts
  register_cms_hosts

  # Restart Nginx service
  sudo systemctl restart nginx
}

cosmic_dep(){
  output "********************************************************"
  output "Installing Cosmic CMS dependencies..."
  output "********************************************************"

  apt_update

  if ! [ -x "$(command -v nginx)" ]; then
    sudo add-apt-repository ppa:ondrej/nginx -y
    sudo apt install -y nginx
  fi

  # Install PHP and its useful modules
  sudo apt install -y software-properties-common

  sudo add-apt-repository ppa:ondrej/php -y

  sudo apt update -y

  sudo apt-get install php8.1 php8.1-common \
    php8.1-curl php8.1-mysql php8.1-opcache \
    php8.1-imap php8.1-fpm mariadb-server -y

  sudo apt install php8.1-xml php8.1-xmlrpc \
    php8.1-gd php8.1-imagick php8.1-cli \
    php8.1-dev php8.1-imap php8.1-mbstring \
    php8.1-soap php8.1-zip php8.1-intl unzip -y

  # Install Composer v2

  curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
  sudo php /tmp/composer-setup.php --install-dir=/usr/bin --filename=composer

  sudo systemctl enable mariadb
  sudo systemctl start mariadb

  sudo apt purge apache2 -y
}

setup_cosmic_database(){
  output "Execute database SQL"
  mysql -u root "-p$DB_PASSWORD" ${DB_DATABASE} < $SCRIPT_PATH/cosmic-assets/Database/2.6.sql 
  mysql -u root "-p$DB_PASSWORD" ${DB_DATABASE} < $SCRIPT_PATH/cosmic-assets/Database/upload_fix_and_mailservice.sql 

  echo "Database Created & Configured!"
}

cloudflare(){
  # Check if folder not exist then create a new one.
  if ! [ -d "/opt/scripts" ]; then
    mkdir /opt/scripts
  fi

  # Create file
  touch /opt/scripts/cloudflare-ip-whitelist-sync.sh

  curl -o /opt/scripts/cloudflare-ip-whitelist-sync.sh $GITHUB_URL/cloudflare/cloudflare-ip-whitelist-sync.sh

  # Set permissions to execute scripts
  sudo chmod +x /opt/scripts/cloudflare-ip-whitelist-sync.sh

  # Execute scripts
  sudo sh /opt/scripts/cloudflare-ip-whitelist-sync.sh

  # Append text into nginx.conf
  sed -i '/\/etc\/nginx\/sites-enabled\/\*/a include /etc/nginx/cloudflare;' /etc/nginx/nginx.conf

  # Create cron job
  curl -o /etc/crontab $GITHUB_URL/crontab/crontab

  sudo systemctl restart nginx
}
