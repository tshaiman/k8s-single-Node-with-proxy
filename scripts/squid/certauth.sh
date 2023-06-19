#!/bin/bash
set -x
#######################################
echo "Deploy Squid Proxy Server"
#########################################
echo "new Squid installation Process "
sudo apt update && sudo apt upgrade -y && sudo apt install libssl-dev pkg-config build-essential autoconf apache2-utils
wget http://www.squid-cache.org/Versions/v4/squid-4.12.tar.gz 
tar xvzf squid-4.12.tar.gz
cd squid-4.12
./configure --with-openssl  --enable-ssl-crtd
sudo make && sudo make install
sudo rm /usr/local/squid/etc/squid.conf && sudo cp ../squid-certauth.conf /usr/local/squid/etc/squid.conf
mkdir -p /home/azureuser/ssl_cert
cd /home/azureuser/ssl_cert
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout myCert.pem  -out myCert.pem -subj "/C=IN/ST=KARNATAKA/L=BANGALORE/O=MICROSOFT/OU=ARC/CN=$1/emailAddress=test@email.com"
/usr/local/squid/libexec/security_file_certgen -c -s /home/azureuser/ssl_cert/ssl_db -M 4MB
cp /home/azureuser/ssl_cert/myCert.pem /home/azureuser/myCert.crt


groupadd -g 123 squid
useradd -g squid squid
cd /usr/local/squid
sudo chown -R squid:squid /usr/local/squid
sudo cp -r /home/azureuser/ssl_cert /usr/local/squid/
sudo chmod -R 700 /usr/local/squid/ssl_cert
sudo mkdir -p /var/lib/squid/
sudo chown squid:squid /var/lib/squid
sudo chown azureuser:azureuser /home/azureuser/myCert.crt
sudo chmod 777 /usr/local/squid/var/logs
sudo /usr/local/squid/sbin/squid start


