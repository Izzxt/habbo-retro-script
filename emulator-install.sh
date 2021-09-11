#!/bin/bash

output(){
  echo -e '* '$1'';
}

noted(){
  echo -e '* \e[33m'$1'';
}

error(){
  echo -e '* \e[31m'$1'\e[0m';
}

# Initial variables
DB_Database=''
DB_User=''
DB_Password=''

EMU_LINK=https://git.krews.org/morningstar/Arcturus-Community/uploads/de3d8c4685a302f34ee73acad3b5b381/3-0-0-stable.rar

main(){
  if [[ $EUID -ne 0 ]]; then
    echo "* This script must be executed with root privileges (sudo)." 1>&2
    exit 1
  fi

  output "********************************************************"
  output ""
  error "Please noted! once you run this scripts you can't revert back."
  output "********************************************************"
  output "Setting up Arcturus Emulator"
  output "********************************************************"

  echo -en '*\e[36m Database : \e[0m';
  read -r DB_INPUT

  [ -z "$DB_INPUT" ] || DB_Database=$DB_INPUT

  echo -en '*\e[36m Database User : \e[0m';
  read -r DB_USER_INPUT

  [ -z "$DB_USER_INPUT" ] || DB_User=$DB_USER_INPUT

  echo -en '*\e[36m Database Pass : \e[0m';
  read -r DB_PASS_INPUT

  [ -z "$DB_USER_INPUT" ] || DB_Password=$DB_PASS_INPUT

  emu_setup

  output "********************************************************"
  output "Setup Completed"
  output "********************************************************"
  output "to run the emulator follow the step below :"
  output "[1] screen -S emu"
  output "[2] cd ./3-0-0-stable"
  output "[3] ./run.sh"
  noted "[-] Ctrl + a d (to deattach screen)"
  noted "[-] screen -r emu (to reattach screen)"
  noted "All others information please read README in github"
  output "********************************************************"
  output "Thanks for installing Arcturus Emulator"
  output "Link to Cosmic github :"
  output "https://git.krews.org/morningstar/Arcturus-Community"
  error "PLEASE REBOOT YOUR MACHINE !"
}

emu_setup(){
  # Install screen
  sudo apt-get -y install screen
  
  # Install Unrar packages
  sudo apt-get -y install unrar

  # Install wget
  sudo apt-get -y install wget

  # Install Java Development Kit
  sudo apt-get -y install default-jdk

  # Install arcturus emulator with wget
  wget $EMU_LINK 

  mkdir ./3-0-0-stable

  # Extract emulator file 
  unrar e ./3-0-0-stable.rar ./3-0-0-stable/

  # Remove emulator rar
  rm -rf ./3-0-0-stable.rar
  
  # Replace database inside config.ini
  sed -i -e "s/db.database=arcturus/db.database=${DB_Database}/g" ./3-0-0-stable/config.ini

  # Replace database inside config.ini
  sed -i -e "s/db.username=root/db.username=${DB_User}/g" ./3-0-0-stable/config.ini

  # Replace database inside config.ini
  sed -i -e "s/db.password=password/db.password=${DB_Password}/g" ./3-0-0-stable/config.ini

  # Execute sql file
  output "Execute arcturus base database"
  mysql -u root -p ${DB_Database} < ./3-0-0-stable/arcturus_3.0.0-stable_base_database.sql
  
  output "Enter until finish"
  mysql -u root -p ${DB_Database} -e "ALTER TABLE .users ADD secret_key varchar(40) NULL DEFAULT NULL;"
  mysql -u root -p ${DB_Database} -e "ALTER TABLE users ADD pincode varchar(11) NULL DEFAULT NULL;"
  mysql -u root -p ${DB_Database} -e "ALTER TABLE users ADD extra_rank int(2) NULL DEFAULT NULL;"
  mysql -u root -p ${DB_Database} -e "ALTER TABLE bans MODIFY COLUMN machine_id varchar(255)NOT NULL DEFAULT '';"
  mysql -u root -p ${DB_Database} -e "ALTER TABLE users ADD template enum('light','dark') NULL DEFAULT 'light';"
  mysql -u root -p ${DB_Database} -e "SET FOREIGN_KEY_CHECKS = 1;"


  # Create new run.sh file
bash -c "cat > ./3-0-0-stable/run.sh" << EOF
#!/bin/bash

java -jar Habbo-3.0.0-jar-with-dependencies.jar
EOF

# Give execute permissions
chmod +x ./3-0-0-stable/run.sh
chown -R $USER:$USER ./3-0-0-stable
}

main
