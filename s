#!/bin/bash

echo "Restore snapshot"
sudo lxc restore u1 fresh
echo "Push file"
sudo lxc file push -r ../HBS u1/root/
echo "Add network config"
sudo lxc config device add u1 web proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
sudo lxc config device add u1 emu proxy listen=tcp:0.0.0.0:2096 connect=tcp:127.0.0.1:2096
echo "Exec container"
sudo lxc exec u1 bash
