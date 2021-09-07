#!/bin/bash

output(){
    echo -e '* \e[36m'$1'\e[0m';
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

  output "Please select your installation option:"
  output "[1] Install CMS"
  output "[2] Install Nitro"
  output "[3] Install Morningstar Emulator"
  output "[4] Install CMS / Nitro / Arcturus Emulator"
  
  input choice

  case $choice in
    1 ) option=1
        output "You have selected CMS installation only"
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
}

selection_option(){
  if [ "$option" = "1" ]; then
    output "1"
  elif [ "$option" = "2" ]; then
    output "2"
  elif [ "$option" = "3" ]; then
    output "3"
  elif [ "$option" = "4" ]; then
    output "4"
  fi
}
# Excutions

install
selection_option
