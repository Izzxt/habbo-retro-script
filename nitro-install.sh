#!/bin/bash

output(){
  echo -e '* '$1'';
}

error(){
  echo -e '* \e[31m'$1'\e[0m';
}

DB_NAME=""
DOMAIN=""

main(){
  if [[ $EUID -ne 0 ]]; then
    error "This script must be executed with root privileges (sudo)." 1>&2
    exit 1
  fi

  output "********************************************************"
  output ""
  error "Please noted! once you run this scripts you can't revert back."
  output ""
  output "********************************************************"
  output "Installing Nitro..."
  output "********************************************************"
  output ""
  echo -en "* Database Name : "
  read -r DB_INPUT

  [ -z "$DB_INPUT" ] || DB_NAME=$DB_INPUT

  output ""
  echo -en "* Website Domain (nitro.local) : "
  read -r DOMAIN_INPUT

  [ -z "$DOMAIN_INPUT" ] && DOMAIN="nitro.local" || DOMAIN=$DOMAIN_INPUT

  output ""
  echo -en "* Would you like to use HTTPS? (Y/N) : "
  read -r answer

  output ""
  output "Please choose your CMS"
  output "[1] Cosmic CMS"
  output "[2] Instinct CMS"
  output ""
  echo -en '* \e[36m'Input [ 1 or 2 ]'\e[0m : '
  read -r cms_opts

  case $cms_opts in
    1 ) choice=1
      output "You have choose Cosmic CMS config."
      ;;
    2 ) choice=2
      output "You have choose Instinct CMS config."
      ;;
    * ) error "Invalid Input"
      main
  esac

  output ""
  output "Please choose which web server do you want to use."
  output "[1] Nginx"
  output "[2] Apache2"
  output ""
  echo -en '* \e[36m'Input [ 1 or 2 ]'\e[0m : '
  read -r webs_opts

  case $webs_opts in
    1 ) webs_choice=1
      output "You have choose Nginx web server"
      ;;
    2 ) webs_choice=2
      output "You have choose Apache2 web server"
      ;;
    * ) error "Invalid Input"
  esac

  cms_config
  webserver
  setup_nitro
  update_config
  summary
}

setup_nitro(){ 
  # Check if packages already exist skip, else Install 16v.NodeJS
  if [ $(dpkg-query -W -f='${Status}' nodejs 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi

  # Clone nitro
  git clone https:/|git.krews.org/nitro/nitro-client.git --branch dev

  cd nitro-client

  # Install npm packages
  npm i

  # Rename config file
  mv src/index.html.example src/index.html 

  mv src/ui-config.json.example src/ui-config.json 

  mv src/renderer-config.json.example src/renderer-config.json 

  # Build nitro dist
  npm run build-prod

  # Create Nitro directory for web server
  mkdir /var/www/Nitro

  # Move nitro dist folder to Nitro web server folder, and delete dist folder
  mv dist/* /var/www/Nitro
  rm dist

  # Clone into default-assets
  git clone https://git.krews.org/nitro/default-assets.git

  mv default-assets/images /var/www/Nitro

  mv default-assets/room /var/www/Nitro

  rm -rf default-assets

  cd /var/www/Nitro

  # Create bundled directory 
  mkdir bundled

  # Clone into oshawott nitro-assets
  git clone https://git.krews.org/oshawott/nitro-assets.git

  # Move all assets to bundled directory
  mv nitro-assets/* bundled

  # Remove nitro-assets directory
  rm -rf nitro-assets
}

cms_config(){

  if [ "$cms_opts" = "1" ]; then
    if [[ "$answer" =~ [Yy] ]]; then
      sudo sed -i -e "s|https://client.circinus.dev|https://${DOMAIN}|g" /var/www/Cosmic/src/App/Config.php
    else
      sudo sed -i -e "s|https://client.circinus.dev|http://${DOMAIN}|g" /var/www/Cosmic/src/App/Config.php
    fi
  elif [ "$cms_opts" = "2" ]; then
      output "instinct"
  fi
}

update_config(){
  if [[ "$answer" =~ [Yy] ]]; then
    # Replace config file for https
    sed -i -e "s|SOCKET_URL|wss://${DOMAIN}:2096|g" dist/renderer-config.json

    # asset.url for https
    sed -i -e "s|ASSET_URL|https://${DOMAIN}|g" dist/renderer-config.json
  else
    # Replace config file for http
    sed -i -e "s|SOCKET_URL|ws://${DOMAIN}:2096|g" dist/renderer-config.json

    # asset.url for http
    sed -i -e "s|ASSET_URL|http://${DOMAINJ}|g" dist/renderer-config.json
  fi

  # C_IMAGES
  sed -i -e 's|C_IMAGES_WITH_SLASH/|${asset.url}/c_images/|g' dist/renderer-config.json

  # gamedata.url
  sed -i -e 's|${asset.url}/gamedata|${asset.url}/bundled/gamedata|g' dist/renderer-config.json

  # sounds.url
  sed -i -e 's|${asset.url}/sounds|${asset.url}/bundled/furniture/sounds|g' dist/renderer-config.json

  # external.samples.url
  sed -i -e 's|${hof.furni.url}/mp3/sound_machine_sample_%sample%.mp3|${sounds.url}/sound_machine_sample_%sample%.mp3|g' dist/renderer-config.json

  # furnidata.url
  sed -i -e 's|${gamedata.url}/json|${asset.url}/bundled|g' dist/renderer-config.json

  # productdata.url
  sed -i -e 's|${gamedata.url}/json/ProductData.json|${asset.url}/bundled/furniture/json/ProductData.json|g' dist/renderer-config.json

  # avatar.figuredata.url
  sed -i -e 's|${gamedata.url}/json/FigureData.json|${asset.url}/bundled/figure/json/FigureData.json|g' dist/renderer-config.json

  # avatar.figuremap.url
  sed -i -e 's|${gamedata.url}/json/FigureMap.json|${asset.url}/bundled/figure/json/FigureMap.json|g' dist/renderer-config.json

  # avatar.effectmap.url
  sed -i -e 's|${gamedata.url}/json/EffectMap.json|${asset.url}/bundled/effects/json/EffectMap.json|g' dist/renderer-config.json

  # avatar.asset.effect.url
  sed -i -e 's|${asset.url}/bundled/effect/%libname%.nitro|${asset.url}/bundled/effects/nitro/%libname%.nitro|g' dist/renderer-config.json

  # avatar.asset.url
  sed -i -e 's|${asset.url}/bundled/figure/%libname%.nitro|${asset.url}/bundled/figure/nitro/%libname%.nitro|g' dist/renderer-config.json

  # furni.asset.url
  sed -i -e 's|${asset.url}/bundled/furniture/%libname%.nitro|${asset.url}/bundled/furniture/nitro/%libname%.nitro|g' dist/renderer-config.json

  # furni.asset.icon.url
  sed -i -e 's|${hof.furni.url}/icons/%libname%%param%_icon.png|${asset.url}/bundled/furniture/icons/%libname%%param%_icon.png|g' dist/renderer-config.json

  # furni.extras.url
  sed -i -e 's|${images.url}/furniextras/%image%.png|${asset.url}/bundled/furniture/furniextras/%image%.png|g' dist/renderer-config.json

  # pet.asset.url
  sed -i -e 's|${asset.url}/bundled/pet/%libname%.nitro|${asset.url}/bundled/pets/%libname%.nitro|g' dist/renderer-config.json

  # Update emulator settings
  mysql -u root -p ${DB_MAME} -e "UPDATE `emulator_settings` SET `value` = '*' WHERE (`key` = 'websockets.whitelist');"
}

webserver(){
  output "********************************************************"
  output "Setting up web server"
  output "********************************************************"
  if [ "$webs_choice" = "1" ]; then
    nginx_config
  elif [ "$webs_choice" = "2" ]; then
    apache_config
  fi
}

nginx_config(){
bash -c "cat > /etc/nginx/sites-available/$DOMAIN" <<-EOF
server {
	listen 80;
	listen [::]:80;
	server_name ${DOMAIN};
	root /var/www/Nitro;
	index index.html;
	location / {
		try_files \$uri \$uri/ =404;
	}
}
EOF

  # Restart Nginx service
  sudo systemctl restart nginx

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

apache_config(){
  output "apache"
}

register_hosts(){
bash -c "cat >> /etc/hosts" << EOF
127.0.0.1         $DOMAIN
EOF
}

summary(){
  output "********************************************************"
  output "Thanks For Installing Nitro ! ."
  output "********************************************************"
  output ""
  output "You Nitro folder : /var/www/Nitro"
  output ""
  output "Oshawott (for assets)"
  output "https://git.krews.org/oshawott/nitro-assets"
  output ""
  output "Nitro (game engine)"
  output "https://git.krews.org/nitro/nitro-client"
  output ""
  output "********************************************************"
}

main
