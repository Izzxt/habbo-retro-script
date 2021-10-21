#!/bin/bash

output(){
    echo -e '* '$1'';
}

error(){
  echo -e '* \e[31m'$1'\e[0m';
}

# Variables
DOMAIN=""
MYSQL_DB=""
MYSQL_USER=""
MYSQL_PASSWORD=""

main(){
  if [[ $EUID -ne 0 ]]; then
    echo "* This script must be executed with root privileges (sudo)." 1>&2
    exit 1
  fi

  # check for curl
  if ! [ -x "$(command -v curl)" ]; then
    echo "* curl is required in order for this script to work."
    echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
    exit 1
  fi

  output "There is only 2 CMS available."
  output "Please choose your CMS:"
  output "[1] Cosmic CMS"
  output "[2] Instinct CMS"
  echo -en '* \e[36m'Input [ 1 or 2 ]'\e[0m : '
  read -r cms_opts

  case $cms_opts in
    1 ) choice=1
      output "You have choose to install Cosmic CMS"
      ;;
    2 ) choice=2
      output "You have choose to install Instinct CMS"
      ;;
    * ) error "Invalid Input"
      main
  esac
  cms_selection
}

cms_selection(){
  if [ "$choice" = "1" ]; then
    configure_webs
    cosmic
    cosmic_summary
  elif [ "$choice" = "2" ]; then
    configure_webs
    instinct
    instinct_summary
  fi
}

cosmic(){
  output "********************************************************"
  output ""
  error "Please noted! once you run this scripts you can't revert back."
  output ""
  output "********************************************************"
  output "Installing Cosmic CMS..."
  output "********************************************************"

  echo -en '*\e[36m Website Domain (cosmic.local) : \e[0m';
  read -r DOMAIN_INPUT

  [ -z "$DOMAIN_INPUT" ] && DOMAIN="cosmic.local" || DOMAIN=$DOMAIN_INPUT

  cosmic_dep

  # Clone into cosmic
  if ! [ -d "/var/www" ]; then
    mkdir /var/www
  fi

  git clone https://git.krews.org/Raizer/cosmic-assets.git

  mv cosmic-assets/Plugin/Webkit.jar ./

  setup_database

  cd /var/www/

  git clone https://git.krews.org/Raizer/Cosmic.git

  mkdir $DOMAIN

  mv Cosmic/* $DOMAIN

  sudo chown -R $USER:www-data /var/www/$DOMAIN

  rm -rf Cosmic

  cd $DOMAIN

  composer install

# Setup .env file
bash -c "cat > /var/www/$DOMAIN/.env" << EOF
DB_DRIVER=mysql
DB_HOST=localhost
DB_NAME=${MYSQL_DB}
DB_USER=${MYSQL_USER}
DB_PASS=${MYSQL_PASSWORD}
DB_CHARSET=utf8
DB_COLLATION=collation
EOF

  webs_configure

}

apt_update(){
  sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove
}

webs_configure(){
  if [ "$webs_choice" = "1" ]; then
    sudo apt-get -y install nginx
    configure_nginx
  elif [ "$webs_choice" = "2" ]; then
    sudo apt-get -y install apache2
    confiure_apache
  fi
}

configure_nginx(){
  output "********************************************************"
  output "Configure Nginx Web Server..."
  output "********************************************************"

  # Enable and start Nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx

  echo -ne "* Are you using cloudflare? (Y/N) : "
  read -r answer

  if [[ "$answer" =~ [Yy] ]]; then
bash -c "cat > /etc/nginx/sites-available/$DOMAIN" <<-EOF
server {
     listen 80;
     listen [::]:80;

     server_name ${DOMAIN};

     root /var/www/$DOMAIN/public;
     index index.php index.html;

     add_header Access-Control-Allow-Origin *;

     location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
     }

     location ~ \.php$ {
         include snippets/fastcgi-php.conf;
         fastcgi_pass unix:/run/php/php-fpm.sock;
     }
}
EOF
cloudflare

  else
bash -c "cat > /etc/nginx/sites-available/$DOMAIN" <<-EOF
server {
     listen 80;
     listen [::]:80;

     server_name ${DOMAIN};

     root /var/www/$DOMAIN/public;
     index index.php index.html;

     add_header Access-Control-Allow-Origin *;

     location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
     }

     location ~ \.php$ {
         include snippets/fastcgi-php.conf;
         fastcgi_pass unix:/run/php/php-fpm.sock;
     }
}
EOF

  # Restart Nginx service
  sudo systemctl restart nginx
  fi

  # Register hosts
  register_hosts

  # Remove default nginx config
  if [ -f "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
  fi

  # Create link to sites-enabled
  sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

  # Restart Nginx service
  sudo systemctl restart nginx
}

confiure_apache(){
  output "********************************************************"
  output "Configure Apache2 Web Server..."
  output "********************************************************"
  
}

register_hosts(){
bash -c "cat >> /etc/hosts" << EOF
127.0.0.1         $DOMAIN
EOF
}

cosmic_dep(){
  output "Installing Cosmic CMS dependencies.."

  apt_update

  # Install 16v.NodeJS
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt-get install -y nodejs

  # Install PHP and its useful modules
  sudo apt install -y software-properties-common

  sudo add-apt-repository ppa:ondrej/php -y

  sudo add-apt-repository ppa:ondrej/nginx -y

  sudo apt update -y

  sudo apt install -y php

  sudo apt-get -y install php-json

  sudo apt-get -y install php-curl

  sudo apt-get -y install php-mbstring

  sudo apt-get -y install php-gd

  sudo apt-get -y install php-fpm

  sudo apt-get -y install php-pdo

  sudo apt-get -y install php-mysql

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
  exit $RESULT
    
  # Install Git
  sudo apt-get -y install git

  # Install MariaDB
  sudo apt-get -y install mariadb-server

  sudo systemctl enable mariadb
  sudo systemctl start mariadb

  sudo systemctl stop apache2
}

configure_webs(){
  output "Please choose which web server do you want to use."
  output "[1] Nginx"
  output "[2] Apache2"
  echo -en '* \e[36m'Input [ 1 or 2 ]'\e[0m : '
  read -r webs_opts

  case $webs_opts in
    1 ) webs_choice=1
      output "You have choose to use Nginx web server"
      ;;
    2 ) webs_choice=2
      output "You have choose to use Apache2 web server"
      ;;
    * ) error "Invalid Input"
  esac
}

setup_database(){
  output "********************************************************"
  output "MariaDB secure installation.. Setting up database..."
  output "********************************************************"
  echo -en '*\e[36m MySQL Database : \e[0m';
  read -r MYSQL_DB

  echo -en '*\e[36m MySQL Username : \e[0m';
  read -r MYSQL_USER

  echo -en '*\e[36m MySQL Password (NO SPACE) : \e[0m';
  password_input

  output "Create MySQL user."
  mysql -u root -p -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"

  output "Create database."
  mysql -u root -p -e "CREATE DATABASE ${MYSQL_DB};"

  output "Grant privileges."
  mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;"

  output "Flush privileges."
  mysql -u root -p -e "FLUSH PRIVILEGES;"

  output "Execute database SQL"
  mysql -u root -p ${MYSQL_DB} < cosmic-assets/Database/2.6.sql 
  mysql -u root -p ${MYSQL_DB} < cosmic-assets/Database/rarevalue.sql 

  echo "Database Created & Configured!"
}


password_input(){
  # Copy Paste from https://stackoverflow.com/a/22940001 i'm lazy
  MYSQL_PASSWORD=''
  while IFS= read -r -s -n1 char; do
    [[ -z $char ]] && { printf '\n'; break; } # ENTER pressed; output \n and break.
    if [[ $char == $'\x7f' ]]; then # backspace was pressed
        # Remove last char from output variable.
        [[ -n $MYSQL_PASSWORD ]] && MYSQL_PASSWORD=${MYSQL_PASSWORD%?}
        # Erase '*' to the left.
        printf '\b \b' 
    else
      # Add typed char to output variable.
      MYSQL_PASSWORD+=$char
      # Print '*' in its stead.
      printf '*'
    fi
  done
}

cloudflare(){
  # Check if folder not exist then create a new one.
  if ! [ -d "/opt/scripts" ]; then
    mkdir /opt/scripts
  fi

  # Create file
  touch /opt/scripts/cloudflare-ip-whitelist-sync.sh

bash -c "cat > /opt/scripts/cloudflare-ip-whitelist-sync.sh" <<-'EOF'
#!/bin/bash

CLOUDFLARE_FILE_PATH=/etc/nginx/cloudflare

echo "#Cloudflare" > $CLOUDFLARE_FILE_PATH;
echo "" >> $CLOUDFLARE_FILE_PATH;

echo "# - IPv4" >> $CLOUDFLARE_FILE_PATH;
for i in `curl https://www.cloudflare.com/ips-v4`; do
        echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "# - IPv6" >> $CLOUDFLARE_FILE_PATH;
for i in `curl https://www.cloudflare.com/ips-v6`; do
        echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_FILE_PATH;

#test configuration and reload nginx
nginx -t && systemctl reload nginx
EOF

  # Set permissions to execute scripts
  sudo chmod +x /opt/scripts/cloudflare-ip-whitelist-sync.sh

  # Execute scripts
  sudo sh /opt/scripts/cloudflare-ip-whitelist-sync.sh

  # Append text into nginx.conf
  sed -i '/\/etc\/nginx\/sites-enabled\/\*/a include /etc/nginx/cloudflare;' /etc/nginx/nginx.conf

  # Create cron job
bash -c "cat >> /etc/crontab" << EOF
30 2 * * * /opt/scripts/cloudflare-ip-whitelist-sync.sh >/dev/null 2>&1
EOF
  sudo systemctl restart nginx
}

cosmic_summary(){
  output "********************************************************"
  output "Installation Completed.."
  output "********************************************************"
  output "MySQL Database : $MYSQL_DB"
  output "MySQL Username : $MYSQL_USER"
  output "MySQL Password : $MYSQL_PASSWORD"
  output "Website Domain : $DOMAIN"
  output "********************************************************"
  output "DIR : /var/www/$DOMAIN"
  output "Thanks for installing Cosmic"
  output "Link to Cosmic github :"
  output "https://git.krews.org/Raizer/Cosmic"
  output "Credits to Raizer"
}

main
