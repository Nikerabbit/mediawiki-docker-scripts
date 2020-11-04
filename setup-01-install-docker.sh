#!/bin/bash
#
# Setup MediaWiki docker on Debian

################################################################
##################    Install Docker CE   ######################
################################################################

# Update the apt package index:
sudo apt-get update

# Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install --yes \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common \
     lbzip2

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -

# Add Docker's stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"

# Update the apt package index:
sudo apt-get update

# Install the latest version of Docker CE
sudo apt-get --yes install docker-ce


################################################################
##############    Install Docker Compose    ####################
################################################################

sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

################################################################
#####################    MediaWiki    ##########################
################################################################

sudo apt-get install --yes git
