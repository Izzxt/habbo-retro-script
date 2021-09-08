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
    summary
  elif [ "$choice" = "2" ]; then
    configure_webs
    instinct
    summary
  fi
}

cosmic(){
  output "********************************************************"
  output "Installing Cosmic CMS..."
  output "********************************************************"

  echo -en '*\e[36m Website Domain (cosmic.local) : \e[0m';
  read -r DOMAIN_INPUT

  [ -z "$DOMAIN_INPUT" ] && DOMAIN="cosmic.local" || DOMAIN=$DOMAIN_INPUT

  cosmic_dep
  webs_configure
  setup_database

  # Clone into cosmic
  if ! [ -d "/var/www" ]; then
    mkdir /var/www
  fi
  cd /var/www/
  git clone https://git.krews.org/Raizer/Cosmic.git
  cd Cosmic
  git clone https://git.krews.org/Raizer/cosmic-assets.git

bash -c 'cat > /var/www/Cosmic/.env' << EOF
DB_DRIVER=mysql
DB_HOST=localhost
DB_NAME=${MYSQL_DB}
DB_USER=${MYSQL_USER}
DB_PASS=${MYSQL_PASSWORD}
DB_CHARSET=utf8
DB_COLLATION=collation
EOF
}

apt_update(){
  sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove
}

webs_configure(){
  if [ "$webs_choice" = "1" ]; then
    configure_nginx
  elif [ "$webs_choice" = "2" ]; then
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

  if [ "$answer" =~ [Yy] ]; then
bash -c "cat > /etc/nginx/sites-available/$DOMAIN" << EOF
server {
     listen 81;
     listen [::]:81;

     server_name ${DOMAIN};

     root /var/www/Cosmic/public;
     index index.html index.php;

     location / {
        try_files $uri $uri/ /index.php?$query_string;
     }

     http { 
        include /etc/nginx/cloudflare 
     }
}
EOF
  else
bash -c "cat > /etc/nginx/sites-available/$DOMAIN" << EOF
server {
     listen 81;
     listen [::]:81;

     server_name ${DOMAIN};

     root /var/www/Cosmic/public;
     index index.html index.php;

     location / {
        try_files $uri $uri/ /index.php?$query_string;
     }
}
EOF
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

cosmic_dep(){
  output "Installing Cosmic CMS dependencies.."

  apt_update

  # Install 16v.NodeJS
  curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
  sudo apt-get install -y nodejs

  # Install PHP and its useful modules
  sudo apt-get -y install php-json

  sudo apt-get -y install php-curl

  sudo apt-get -y install php-mbstring

  # Install Composer
  sudo apt-get install composer

  # Install Git
  sudo apt-get install git

  # Install Web Server
  if [ "$webs_choice" = "1" ]; then
    sudo apt-get -y install nginx
  elif [ "$webs_choice" = "2" ]; then
    sudo apt-get -y install apache2
  fi

  # Install MariaDB
  sudo apt-get install mariadb-server

  # Install PHPMyAdmin
  sudo apt-get install phpmyadmin

  sudo systemctl enable mariadb
  sudo systemctl start mariadb
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
  sudo mariadb-secure-installation
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
  mysql -u root -p -e "CREATE USER '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"

  output "Create database."
  mysql -u root -p -e "CREATE DATABASE ${MYSQL_DB};"

  output "Grant privileges."
  mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION;"

  output "Flush privileges."
  mysql -u root -p -e "FLUSH PRIVILEGES;"

  output "Execute database SQL"
  mysql -u root -p < /var/www/Cosmic/Database/2.6.sql 
  mysql -u root -p < /var/www/Cosmic/Database/rarevalue.sql 

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

summary(){
  output "********************************************************"
  output "Installation Completed.."
  output "********************************************************"
  output "MySQL Database : $MYSQL_DB"
  output "MySQL Username : $MYSQL_USER"
  output "MySQL Password : $MYSQL_PASSWORD"
  output "Website Domain : $DOMAIN"
  output "********************************************************"
  output "Thanks for installing Cosmic"
  output "Link to Cosmic github :"
  output "https://git.krews.org/Raizer/Cosmic"
  output "Credits to Raizer"
}

main
