#!/bin/bash
#######################################
echo "Deploy Squid Proxy Server"
#########################################
#sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y libssl-dev pkg-config build-essential autoconf apache2-utils

# wget  http://www.squid-cache.org/Versions/v5/squid-5.9.tar.gz
# tar xvzf squid-5.9.tar.gz
# cd squid-5.9
# ./configure --with-openssl  --enable-ssl-crtd
# sudo make && sudo make install
# sudo mv ./squid-noauth.conf /usr/local/squid/etc/squid.conf
# sudo chmod 777 /usr/local/squid/var/logs
# sudo /usr/local/squid/sbin/squid start



echo "new Squid installation Process "


sudo apt update && sudo apt upgrade -y && sudo apt install squid -y
sudo cp ./squid-noauth.conf /etc/squid/squid.conf
sudo systemctl restart squid.service