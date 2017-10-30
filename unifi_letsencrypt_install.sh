#!/bin/bash
##
## Author: David Griffin - https://github.com/Davie3
## Date: 10/30/17
## Title: UniFi Let's Encrypt Renewal
## Description: Generates and installs a Let's Encrypt certificate for the specified domain then adds it to the UniFi key store.
##              Assumes you already have a working version of the UniFi Controller installed.
## Requirements: Certbot - https://certbot.eff.org
##		 		 UniFi - https://www.ubnt.com/download/unifi
## Disclaimer: Use at your own risk! Always make a backup of your UniFi install. It is very easy to restore a UniFi backup if something were to go wrong.
##

#Change the following variables accordingly:
DOMAIN="www.example.com"
EMAIL="email@example.com"
KEYSTORE_PASS="aircontrolenterprise" #This is the default UniFi key store password.
DISTRO=$(cat /etc/*-release)

echo "Installing Certbot - https://certbot.eff.org"

if [[ ${DISTRO,,} == *"ubuntu"* ]]; then
	#PPA for Ubuntu
	apt-get update
	apt-get install software-properties-common -y
	add-apt-repository ppa:certbot/certbot -y
fi

apt-get update

if [[ ${DISTRO,,} == *"jessie"* ]]; then
	#For Debian Jessie. See https://certbot.eff.org/#debianjessie-other
	apt-get install certbot -t jessie-backports -y
else
	apt-get install certbot -y
fi

echo "Generating Let's Encrypt standalone certificate for $DOMAIN"
certbot certonly --standalone --agree-tos --keep -d $DOMAIN -m $EMAIL
#certbot certonly --standalone --agree-tos --keep -d $DOMAIN -m $EMAIL --staging
#certbot certonly --standalone --agree-tos --no-eff-email --keep -d $DOMAIN -m $EMAIL

echo "Exporting $DOMAIN certificate with openssl"
openssl pkcs12 -export -in /etc/letsencrypt/live/$DOMAIN/cert.pem -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem -out /etc/letsencrypt/live/$DOMAIN/$DOMAIN.p12 -name unifi -CAfile /etc/letsencrypt/live/$DOMAIN/chain.pem -caname root -password pass:$KEYSTORE_PASS

if [ -f /etc/letsencrypt/live/$DOMAIN/$DOMAIN.p12 ]; then
	echo "Backing up UniFi keystore"
	cp /var/lib/unifi/keystore /var/lib/unifi/keystore.original
	#Keep this safe if you ever have an issue!

	echo "Removing default UniFi certificate"
	keytool -delete -alias unifi -keystore /var/lib/unifi/keystore -storepass $KEYSTORE_PASS -noprompt

	echo "Importing Let's Encrypt $DOMAIN certificate"
	keytool -importkeystore -deststorepass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS -destkeystore /var/lib/unifi/keystore -srckeystore /etc/letsencrypt/live/$DOMAIN/$DOMAIN.p12 -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASS -alias unifi -noprompt

	echo "Restarting UniFi service"
	service unifi restart
else
   echo "An error has occured. The certificate was not generated. Please verify the Certbot packages installed properly and that you have sufficient permission."
   echo "Refer to Certbot's documentation for errors generating certficates with your server and domain: https://certbot.eff.org/docs/"
fi
