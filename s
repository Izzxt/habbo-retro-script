#!/bin/bash

echo "Restore snapshot"
sudo lxc restore u1 fresh
echo "Push file"
sudo lxc file push -r ../HBS u1/root/
echo "Exec container"
sudo lxc exec u1 bash
