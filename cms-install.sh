#!/bin/bash

output(){
    echo -e '* '$1'';
}

option_cms(){
  output "There is only 2 CMS available."
  output "Please choose your CMS:"
  output "[1] Cosmic CMS"
  output "[2] Instinct CMS"
  echo -en '* \e[36m'Input [ 1 or 2 ]'\e[0m : '
  read -r cms_opts

  case cms_opts in
    1 ) choice=1
      output "You have choose to install Cosmic CMS"
      ;;
    2 ) choice=2
      output "You have choose to install Instinct CMS"
      ;;
    * ) error "Invalid Input"
      option_cms
  esac
}

cms_selection(){
  if [ "$choice" = "1" ]; then
    output "1"
  elif [ "$choice" = "2" ]; then
    output "2"
  fi
}

option_cms
cms_selection
