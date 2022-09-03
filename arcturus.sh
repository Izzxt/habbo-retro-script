#!/bin/bash

RELEASE=https://git.krews.org/morningstar/Arcturus-Community/uploads/7d11f511bd40ebc30288f5458cdac4a7/Arcturus_MS_351_STABLE.zip

arcturus_dep(){
  sudo apt-get install unzip wget default-jre -y
}

arcturus_setup(){
  mkdir ./emulator

  # Extract emulator file 
  curl -o emulator.zip $RELEASE

  # Remove emulator rar
  mv emulator.zip ./emulator

  cd ./emulator

  unzip emulator.zip

  rm emulator.zip

  cd ..

  mv "$SCRIPT_PATH/emulator/base database/BASEDB_ARCMS_350_STB-925b0513883fa34a34c3a00b59a17833.sql" ./emulator
  
  # Replace database inside config.ini
  sed -i -e "s/db.database=arcturusms/db.database=${DB_DATABASE}/g" $SCRIPT_PATH/emulator/config.ini

  sed -i -e "s/db.username=root/db.username=${DB_USERNAME}/g" $SCRIPT_PATH/emulator/config.ini

  sed -i -e "s/db.password=/db.password=${DB_PASSWORD}/g" $SCRIPT_PATH/emulator/config.ini

  sed -i -e "s/db.params=/db.params=?useSSL=false/g" $SCRIPT_PATH/emulator/config.ini

  arcturus_configure_database

  # Create new run.sh file
  bash -c "cat > $SCRIPT_PATH/emulator/emulator" << EOF
#!/bin/sh
java -Dfile.encoding=UTF8 -Xmx4096m -jar /srv/Arcturus/Habbo-3.5.1-jar-with-dependencies.jar > /var/log/emulator.log
EOF

mv ./emulator /srv/Arcturus

# Give execute permissions
cd /srv/Arcturus
chmod +x emulator
sudo chown -R $USER:$USER /srv/Arcturus

curl -o /etc/systemd/system/arcturus.service $GITHUB_URL/systemd/arcturus.service

sudo systemctl enable arcturus.service
sudo systemctl start arcturus.service
}

arcturus_configure_database(){
  # Execute sql file
  output "Execute arcturus base database"
  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} < "$SCRIPT_PATH/emulator/BASEDB_ARCMS_350_STB-925b0513883fa34a34c3a00b59a17833.sql"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "ALTER TABLE users ADD secret_key varchar(40) NULL DEFAULT NULL;"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "ALTER TABLE users ADD pincode varchar(11) NULL DEFAULT NULL;"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "ALTER TABLE users ADD extra_rank int(2) NULL DEFAULT NULL;"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "ALTER TABLE bans MODIFY COLUMN machine_id varchar(255)NOT NULL DEFAULT '';"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "ALTER TABLE users ADD template enum('light','dark') NULL DEFAULT 'light';"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "SET FOREIGN_KEY_CHECKS = 1;"

  mysql -u root "-p${DB_PASSWORD}" ${DB_DATABASE} -e "UPDATE emulator_settings SET value='0' WHERE  \`key\`='console.mode';"
  
}
