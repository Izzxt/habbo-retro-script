#!/bin/bash

SCRIPT_PATH=$(pwd)

BRANCH='new-script'
GITHUB_URL="https://raw.githubusercontent.com/Izzxt/habbo-retro-script/$BRANCH"

DB_DATABASE=''
DB_USERNAME=''
DB_PASSWORD=''
CMS_DOMAIN=''
NITRO_DOMAIN=''
WS_NITRO_DOMAIN=''

output(){
    echo -e '* '$1'';
}

input(){
    echo -en '*\e[36m Input [ 1 - 4 ] : \e[0m';
    read -r $1
}

error(){
    echo -e '* \e[31m'$1'\e[0m';
}

apt_update(){
  sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove
}

install() {
  if [ "$EUID" -ne 0 ]; then
    error "You must run as root to use this script."
    exit 3
  fi

  if ! [ -x "$(command -v curl)" ]; then
    echo "* curl is required in order for this script to work."
    echo "* install using sudo apt install"
    exit 1
  fi

  echo "$SCRIPT_PATH/cosmic-assets/Database/2.6.sql"
  output "********************************************************"
  output "Please choose your installation option."
  output "********************************************************"
  output "[1] Install CMS"
  output "[2] Install Nitro"
  output "[3] Install Morningstar Emulator"
  output "[4] Install CMS / Nitro / Arcturus Emulator"
  
  input choice

  case $choice in
    1 ) option=1
        output "You have selected CMS installation only"
      # option_cms
        ;;
    2 ) option=2
        output "You have selected Nitro installation only"
        ;;
    3 ) option=3
        output "You have selected Arcturus Emulator installation only"
        ;;
    4 ) option=4
        output "You have selected to install CMS | Nitro | Arcturus Emulator"
        ;;
    * ) error "Invalid Input"
        install
    esac
    selection_option
}

selection_option(){
  if [ "$option" = "1" ]; then
    source ./cosmic.sh
    cms_prompt
    cms_domain_prompt
    web_prompt
    database_prompt
    cms_selection
  elif [ "$option" = "2" ]; then
    source ./nitro.sh
    nitro_domain_prompt
    cms_config
    nitro_dep
    nitro_setup
    nitro_configure_web
    nitro_plugin
  elif [ "$option" = "3" ]; then
    source ./arcturus.sh
    database_prompt
    apt_update
    sudo apt-get install mariadb-server -y
    arcturus_dep
    setup_database
    arcturus_setup
  elif [ "$option" = "4" ]; then
    source ./arcturus.sh
    source ./nitro.sh
    source ./cosmic.sh
    cms_prompt
    cms_domain_prompt
    web_prompt
    nitro_domain_prompt
    database_prompt
    apt_update
    cosmic_dep
    nitro_dep
    arcturus_dep
    setup_database
    arcturus_setup
    setup_cosmic

    if [ "$cms_config_choice" = "1" ]; then
      if [[ "$cms_config_answer" =~ [Yy] ]]; then
        sudo sed -i -e "s|https://comsic.devraizer.nl|https://${CMS_DOMAIN}|g" /var/www/$CMS_DOMAIN/src/App/Config.php
      else
        sudo sed -i -e "s|https://cosmic.devraizer.nl|http://${CMS_DOMAIN}|g" /var/www/$CMS_DOMAIN/src/App/Config.php
      fi
    fi

    web_configure
    setup_cosmic_database
    cms_config
    nitro_setup
    nitro_configure_web
    nitro_plugin

    # Update emulator settings
    mysql -u root "-p${DB_PASSWORD}" -e "UPDATE `emulator_settings` SET `value` = '*' WHERE (`key` = 'websockets.whitelist');"
  fi
}

cms_selection(){
  if [ "$choice" = "1" ]; then
    apt_update
    cosmic_dep
    setup_cosmic
    web_configure
    setup_database
    setup_cosmic_database
  fi
}

setup_database(){
  output "********************************************************"
  output "Setting up database..."
  output "********************************************************"
  output "Create MySQL user."
  mysql -u root "-p$DB_PASSWORD" -e "CREATE USER '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"

  output "Create database."
  mysql -u root "-p$DB_PASSWORD" -e "CREATE DATABASE ${DB_DATABASE};"

  output "Grant privileges."
  mysql -u root "-p$DB_PASSWORD" -e "GRANT ALL PRIVILEGES ON ${DB_DATABASE}.* TO '${DB_USERNAME}'@'localhost' WITH GRANT OPTION;"

  output "Flush privileges."
  mysql -u root "-p$DB_PASSWORD" -e "FLUSH PRIVILEGES;"
}

cms_prompt(){
  echo ""
  output "********************************************************"
  output "Please choose your CMS. There is only 1 CMS available."
  output "********************************************************"
  output "[1] Cosmic CMS"
  output "[x] Instinct CMS"
  echo -en '* \e[36m'Input [ 1 or 1 ]'\e[0m : '
  read -r cms_opts

  case $cms_opts in
    1 ) choice=1
      output "You have choose to install Cosmic CMS"
      ;;
    * ) error "Invalid Input"
      cms_prompt
  esac
}

database_prompt(){
  echo ""
  output "********************************************************"
  output "MariaDB Installation Details..."
  output "********************************************************"
  echo -en '*\e[36m Database: \e[0m';
  read -r DB_INPUT

  [ -z "$DB_INPUT" ] || DB_DATABASE=$DB_INPUT

  echo -en '*\e[36m Username: \e[0m';
  read -r DB_USER_INPUT

  [ -z "$DB_USER_INPUT" ] || DB_USERNAME=$DB_USER_INPUT

  echo -en '*\e[36m Password: \e[0m';
  password_input
}

web_prompt(){
  echo ""
  output "********************************************************"
  output "Please choose which web server do you want to use."
  output "********************************************************"
  output "[1] Nginx"
  output "[x] Apache2"
  echo -en '* \e[36m'Input [ 1 or 1 ]'\e[0m : '
  read -r webs_opts

  case $webs_opts in
    1 ) webs_choice=1
      output "You have choose to use Nginx web server"
      ;;
    * ) error "Invalid Input"
      web_prompt
  esac

  echo -ne "* Are you using cloudflare? (Y/N) : "
  read -r answer
}

plugins(){

  mv Webkit.jar 3-0-0-stable/plugins/

  if ! [ -d "3-0-0-stable/plugins" ]; then
    mkdir 3-0-0-stable/plugins
  fi
  
  cd 3-0-0-stable/plugins

  wget https://cdn.discordapp.com/attachments/641088820598538252/873759980329766942/NitroWebsockets-3.1.jar
}

cms_domain_prompt(){
  echo ''
  echo -en '*\e[36m Website Domain (website.com) : \e[0m';
  read -r DOMAIN_INPUT

  [ -z "$DOMAIN_INPUT" ] && CMS_DOMAIN="website.com" || CMS_DOMAIN=$DOMAIN_INPUT 
}


nitro_domain_prompt(){
  echo ''
  echo -en '*\e[36m Nitro Domain (nitro.website.com) : \e[0m';
  read -r NITRO_DOMAIN_INPUT

  [ -z "$NITRO_DOMAIN_INPUT" ] && NITRO_DOMAIN="nitro.website.com" || NITRO_DOMAIN=$NITRO_DOMAIN_INPUT 
  echo -en '*\e[36m Nitro Websocket Domain (ws.website.com) : \e[0m';
  read -r NITRO_WS_DOMAIN_INPUT

  [ -z "$NITRO_WS_DOMAIN_INPUT" ] && WS_NITRO_DOMAIN="ws.website.com" || WS_NITRO_DOMAIN=$NITRO_WS_DOMAIN_INPUT 

  echo -en "* Would you like to use HTTPS? (Y/N) : "
  read -r cms_config_answer
}

password_input(){
  # Copy Paste from https://stackoverflow.com/a/22940001 i'm lazy
  DB_PASSWORD=''
  while IFS= read -r -s -n1 char; do
    [[ -z $char ]] && { printf '\n'; break; } # ENTER pressed; output \n and break.
    if [[ $char == $'\x7f' ]]; then # backspace was pressed
        # Remove last char from output variable.
        [[ -n $DB_PASSWORD ]] && DB_PASSWORD=${DB_PASSWORD%?}
        # Erase '*' to the left.
        printf '\b \b' 
    else
      # Add typed char to output variable.
      DB_PASSWORD+=$char
      # Print '*' in its stead.
      printf ''
    fi
  done
}

# Excutions
install
