!#/bin/bash

option_cms(){
  output "There is only 2 CMS available."
  output "Please choose your CMS:"
  output "[1] Cosmic CMS"
  output "[2] Instinct CMS"
  echo -en '* \e[36m'Input [ 1 or 2 ]'\e[0m : '
  read -r cms_opts

  case cms_opts in
    1 ) _cms_opts=1
      output "You have choose to install Cosmic CMS"
      ;;
    2 ) _cms_opts=2
      output "You have choose to install Instinct CMS"
      ;;
    * ) error "Invalid Input"
      option_cms
  esac
}

cms_selection(){
  if [ "$_cms_opts" = "1" ]; then
    output "1"
  elif [ "$_cms_opts" = "2" ]; then
    output "2"
  fi
}
