#!/bin/bash
#######################################
echo "Deploy Squid Proxy Server"
#########################################
echo "new Squid installation Process "
sudo apt update && sudo apt upgrade -y && sudo apt install squid apache2-utils -y
sudo htpasswd -b -c /etc/squid/passwords squid squid
sudo cp ./squid-basicauth.conf /etc/squid/squid.conf
sudo systemctl restart squid.service

