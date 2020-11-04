#!/bin/bash

USER=developer
PASS=developer
SCRIPT=setup-03-launch-mediawiki-docker.sh

useradd -p $(openssl passwd -crypt $PASS) -m $USER
sudo usermod -aG docker $USER
cp $SCRIPT /home/$USER
sudo chown $USER:$USER /home/$USER/$SCRIPT
cd /home/$USER
sudo -u $USER ./$SCRIPT
