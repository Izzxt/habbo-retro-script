#!/bin/bash

cms_config(){
  if [[ "$cms_config_answer" =~ [Yy] ]]; then
    sed -i -e "s|https://client.devraizer.nl|https://${NITRO_DOMAIN}|g" /var/www/$CMS_DOMAIN/src/App/Config.php
  else
    sed -i -e "s|https://client.devraizer.nl|http://${NITRO_DOMAIN}|g" /var/www/$CMS_DOMAIN/src/App/Config.php
  fi
}


nitro_dep() {
  apt_update

  if ! [ -x "$(command -v nginx)" ]; then
    sudo add-apt-repository ppa:ondrej/nginx -y
    sudo apt install -y nginx
  fi

  # Check if packages already exist skip, else Install 16v.NodeJS
  if [ $(dpkg-query -W -f='${Status}' nodejs 2>/dev/null | grep -c "ok installed") -eq 0 ];
  then
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
}

nitro_setup(){
  # Clone nitro
  git clone https://git.krews.org/nitro/nitro-react.git
  
  sudo chown -R $USER:$USER ./nitro-react/

  cd nitro-react

  # Install yarn global
  npm i -g yarn

  yarn install

  # Rename config file
  mv public/ui-config.json.example public/ui-config.json 

  mv public/renderer-config.json.example public/renderer-config.json 

  # Build nitro build
  yarn build:prod

  nitro_config

  # Create Nitro directory for web server
  mkdir /var/www/$NITRO_DOMAIN

  # Move nitro build folder to Nitro web server folder, and delete build folder
  mv build/* /var/www/$NITRO_DOMAIN
  rm -rf build

  cd /var/www/$NITRO_DOMAIN

  # Clone c_images
  git clone https://github.com/Izzxt/cata-assets.git

  mv cata-assets/c_images /var/www/$NITRO_DOMAIN

  rm -rf cata-assets

  # Clone into default-assets
  git clone https://git.krews.org/nitro/default-assets.git

  mv default-assets/* /var/www/$NITRO_DOMAIN

  rm -rf default-assets

  # Clone into oshawott nitro-assets
  git clone https://github.com/sphynxkitten/nitro-assets

  # Move all assets to bundled directory
  cp -r nitro-assets/* bundled

  mv gamedata/UITexts.json bundled/gamedata/json

  # Remove nitro-assets directory
  rm -rf nitro-assets
}

nitro_config(){
  if [[ "$cms_config_answer" =~ [Yy] ]]; then
    # Replace config file for https
    sed -i -e "s|wss://ws.website.com:2096|wss://${WS_NITRO_DOMAIN}:2096|g" build/renderer-config.json

    # asset.url for https
    sed -i -e "s|\"asset.url\": \"https://website.com\",|\"asset.url\": \"https://${NITRO_DOMAIN}\",|g" build/renderer-config.json

    sed -i -e "s|https://website.com|https://${NITRO_DOMAIN}|g" build/ui-config.json
  else
    # Replace config file for http
    sed -i -e "s|wss://ws.website.com:2096|ws://${WS_NITRO_DOMAIN}:2096|g" build/renderer-config.json

    # asset.url for http
    sed -i -e "s|\"asset.url\": \"https://website.com\",|\"asset.url\": \"http://${NITRO_DOMAIN}\",|g" build/renderer-config.json

    sed -i -e "s|https://website.com|http://${NITRO_DOMAIN}|g" build/ui-config.json
  fi

  sed -i -e 's|/ui-config.json|./ui-config.json|g' build/index.html

  sed -i -e 's|/renderer-config.json|./renderer-config.json|g' build/index.html

  # C_IMAGES
  sed -i -e 's|https://website.com/c_images/|${asset.url}/c_images/|g' build/renderer-config.json

  # gamedata.url
  sed -i -e 's|${asset.url}/gamedata|${asset.url}/bundled/gamedata/json|g' build/renderer-config.json

  # sounds.url
  sed -i -e 's|${asset.url}/sounds|${asset.url}/bundled/furniture/sounds|g' build/renderer-config.json

  # Externaltexts.json
  sed -i -e 's|${asset.url}/bundled/ExternalTexts.json|${gamedata.url}/json/ExternalTexts.json|g' build/renderer-config.json

  # external.samples.url
  sed -i -e 's|${hof.furni.url}/mp3/sound_machine_sample_%sample%.mp3|${sounds.url}/sound_machine_sample_%sample%.mp3|g' build/renderer-config.json

  # furnidata.url
  sed -i -e 's|${gamedata.url}/FurnitureData.json|${asset.url}/bundled/furniture/json/FurnitureData.json|g' build/renderer-config.json

  # productdata.url
  sed -i -e 's|${gamedata.url}/ProductData.json|${asset.url}/bundled/furniture/json/ProductData.json|g' build/renderer-config.json

  # avatar.figuredata.url
  sed -i -e 's|${gamedata.url}/FigureData.json|${asset.url}/bundled/clothes/json/FigureData.json|g' build/renderer-config.json

  # avatar.figuremap.url
  sed -i -e 's|${gamedata.url}/FigureMap.json|${asset.url}/bundled/clothes/json/FigureMap.json|g' build/renderer-config.json

  # avatar.effectmap.url
  sed -i -e 's|${gamedata.url}/EffectMap.json|${asset.url}/bundled/effects/json/EffectMap.json|g' build/renderer-config.json

  # avatar.asset.effect.url
  sed -i -e 's|${asset.url}/bundled/effect/%libname%.nitro|${asset.url}/bundled/effects/nitro/%libname%.nitro|g' build/renderer-config.json

  # avatar.asset.url
  sed -i -e 's|${asset.url}/bundled/figure/%libname%.nitro|${asset.url}/bundled/clothes/nitro/%libname%.nitro|g' build/renderer-config.json

  # furni.asset.url
  sed -i -e 's|${asset.url}/bundled/furniture/%libname%.nitro|${asset.url}/bundled/furniture/nitro/%libname%.nitro|g' build/renderer-config.json

  # furni.asset.icon.url
  sed -i -e 's|${hof.furni.url}/icons/%libname%%param%_icon.png|${asset.url}/bundled/furniture/icons/%libname%%param%_icon.png|g' build/renderer-config.json

  # furni.extras.url
  sed -i -e 's|${images.url}/furniextras/%image%.png|${asset.url}/bundled/furniture/furniextras/%image%.png|g' build/renderer-config.json

  # pet.asset.url
  sed -i -e 's|${asset.url}/bundled/pet/%libname%.nitro|${asset.url}/bundled/pets/%libname%.nitro|g' build/renderer-config.json
}

nitro_configure_web(){
  curl -o /etc/nginx/sites-available/$NITRO_DOMAIN $GITHUB_URL/nginx/nitro/nginx.conf

  sed -i -e "s|NITRO_DOMAIN|$NITRO_DOMAIN|g" /etc/nginx/sites-available/$NITRO_DOMAIN

  # Remove default nginx config
  if [ -f "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
  fi

  register_nitro_host

  sudo ln -s /etc/nginx/sites-available/$NITRO_DOMAIN /etc/nginx/sites-enabled/

  sudo systemctl restart nginx
}

register_nitro_host(){
bash -c "cat >> /etc/hosts" << EOF
127.0.0.1         $NITRO_DOMAIN
EOF
}

nitro_plugin(){
  if [ -d "/srv/Arcturus" ]; then
    mkdir /srv/Arcturus/plugins
  
    cd /srv/Arcturus/plugins

    wget https://cdn.discordapp.com/attachments/641088820598538252/873759980329766942/NitroWebsockets-3.1.jar

    sudo systemctl restart arcturus
  fi
}
