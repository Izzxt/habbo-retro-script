# used
apt_update(){
  sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove
}

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

  bash -c "cat ./nginx/cosmic/.env >> /var/www/$CMS_DOMAIN/.env"

  sed -i -e "s|DB_NAME=cosmic|DB_NAME=${DB_DATABASE}|g" /var/www/$CMS_DOMAIN/.env

  sed -i -e "s|DB_USER=raizer|DB_NAME=${DB_USERNAME}|g" /var/www/$CMS_DOMAIN/.env

  sed -i -e "s|DB_PASS=meteor123|DB_NAME=${DB_PASSWORD}|g" /var/www/$CMS_DOMAIN/.env

}

# used
register_hosts(){
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
    bash -c "cat ./nginx/cosmic/nginx.conf >> /etc/nginx/sites-available/$CMS_DOMAIN"
    cloudflare
  else
    bash -c "cat ./nginx/cosmic/nginx.conf >> /etc/nginx/sites-available/$CMS_DOMAIN"
  fi

  sed -i -e "s|DOMAIN|$CMS_DOMAIN|g" /etc/nginx/sites-available/$CMS_DOMAIN

  # Create link to sites-enabled
  sudo ln -s /etc/nginx/sites-available/$CMS_DOMAIN /etc/nginx/sites-enabled/

  # Register hosts
  register_hosts

  # Restart Nginx service
  sudo systemctl restart nginx
}

cosmic_dep(){
  output "********************************************************"
  output "Installing Cosmic CMS dependencies..."
  output "********************************************************"

  apt_update

  if ! [ -x "$(command -v nginx)" ]; then
    sudo apt install -y nginx
  fi

  # Install PHP and its useful modules
  sudo apt install -y software-properties-common

  sudo add-apt-repository ppa:ondrej/php -y

  sudo add-apt-repository ppa:ondrej/nginx -y

  sudo apt update -y

  sudo apt-get install -y php
  sudo apt-get install -y php-common 
  sudo apt-get install -y php-curl 
  sudo apt-get install -y php-mbstring 
  sudo apt-get install -y php-gd 
  sudo apt-get install -y php-fpm 
  sudo apt-get install -y php-mysql 
  sudo apt-get install -y php-zip 
  sudo apt-get install -y php-pdo 
  sudo apt-get install -y git 
  sudo apt-get install -y mariadb-server

  # Install Composer v2

  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
    then
        >&2 echo 'ERROR: Invalid installer checksum'
        rm composer-setup.php
        exit 1
  fi

  php composer-setup.php --quiet
  RESULT=$?
  rm composer-setup.php
  
  # Move composer.phar to /usr/local/bin/
  sudo mv composer.phar /usr/local/bin/composer

  sudo systemctl enable mariadb
  sudo systemctl start mariadb

  sudo systemctl stop apache2
}

setup_database(){
  output "********************************************************"
  output "Setting up Cosmic database..."
  output "********************************************************"
  output "Create MySQL user."
  mysql -u root "-p$DB_PASSWORD" -e "CREATE USER '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"

  output "Create database."
  mysql -u root "-p$DB_PASSWORD" -e "CREATE DATABASE ${DB_DATABASE};"

  output "Grant privileges."
  mysql -u root "-p$DB_PASSWORD" -e "GRANT ALL PRIVILEGES ON ${DB_DATABASE}.* TO '${DB_USERNAME}'@'localhost' WITH GRANT OPTION;"

  output "Flush privileges."
  mysql -u root "-p$DB_PASSWORD" -e "FLUSH PRIVILEGES;"

  output "Execute database SQL"
  mysql -u root "-p$DB_PASSWORD" ${DB_DATABASE} < cosmic-assets/Database/2.6.sql 
  mysql -u root "-p$DB_PASSWORD" ${DB_DATABASE} < cosmic-assets/Database/rarevalue.sql 

  echo "Database Created & Configured!"
}

cloudflare(){
  # Check if folder not exist then create a new one.
  if ! [ -d "/opt/scripts" ]; then
    mkdir /opt/scripts
  fi

  # Create file
  touch /opt/scripts/cloudflare-ip-whitelist-sync.sh

  bash -c "cat ./cloudflare/cloudflare-ip-whitelist-sync.sh > /opt/scripts/cloudflare-ip-whitelist-sync.sh"

  # Set permissions to execute scripts
  sudo chmod +x /opt/scripts/cloudflare-ip-whitelist-sync.sh

  # Execute scripts
  sudo sh /opt/scripts/cloudflare-ip-whitelist-sync.sh

  # Append text into nginx.conf
  sed -i '/\/etc\/nginx\/sites-enabled\/\*/a include /etc/nginx/cloudflare;' /etc/nginx/nginx.conf

  # Create cron job
  sudo bash -c "cat ./crontab/crontab >> /etc/crontab"

  sudo systemctl restart nginx
}
