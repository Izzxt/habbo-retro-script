#!/bin/bash

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

  output "Please select your installation option:"
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
        output "You have selected to install CMS / Nitro / Arcturus Emulator"
        ;;
    * ) error "Invalid Input"
        install
    esac
    selection_option
}

selection_option(){
  if [ "$option" = "1" ]; then
    cms
  elif [ "$option" = "2" ]; then
    nitro
  elif [ "$option" = "3" ]; then
    emulator
  elif [ "$option" = "4" ]; then
    cms
    emulator
    nitro
    plugins
  fi
}

cms(){
  # bash <(curl -s https://raw.githubusercontent.com/Izzxt/habbo-retro-script/master/script/cms-install.sh)
  source ./script/cms-install.sh
}

nitro(){
  # bash <(curl -s https://raw.githubusercontent.com/Izzxt/habbo-retro-script/master/script/nitro-install.sh)
  source ./script/nitro-install.sh
}

emulator(){
  # bash <(curl -s https://raw.githubusercontent.com/Izzxt/habbo-retro-script/master/script/emulator-install.sh)
  source ./script/emulator-install.sh
}

plugins(){

  mv Webkit.jar 3-0-0-stable/plugins/

  if ! [ -d "3-0-0-stable/plugins" ]; then
    mkdir 3-0-0-stable/plugins
  fi
  
  cd 3-0-0-stable/plugins

  wget https://cdn.discordapp.com/attachments/641088820598538252/873759980329766942/NitroWebsockets-3.1.jar
}

# Excutions
install
