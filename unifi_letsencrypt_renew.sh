#!/bin/bash
##
## Author: David Griffin - https://github.com/Davie3
## Date: 10/30/17
## Title: UniFi Let's Encrypt Renewal
## Description: Checks Let's Encrypt for certificate renewals and adds the specified domain's certificate to the UniFi key store.
##              Assumes you already have a working version of the UniFi Controller installed.
##              Also assumes you already have a working Let's Encrypt certficate. Refer to my install script if necessary.
## Requirements: Certbot - https://certbot.eff.org
##		 		 UniFi - https://www.ubnt.com/download/unifi
## Disclaimer: Use at your own risk! Always make a backup of your UniFi install. It is very easy to restore a UniFi backup if something were to go wrong.
##

#Change the following variables accordingly:
DOMAIN="www.example.com"
KEYSTORE_PASS="aircontrolenterprise" #This is the default UniFi key store password.

echo "Checking Let's Encrypt for certificate renewals"
certbot renew
#certbot renew --dry-run

echo "Exporting $DOMAIN certificate with openssl"
openssl pkcs12 -export -in /etc/letsencrypt/live/$DOMAIN/cert.pem -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem -out /etc/letsencrypt/live/$DOMAIN/$DOMAIN.p12 -name unifi -CAfile /etc/letsencrypt/live/$DOMAIN/chain.pem -caname root -password pass:$KEYSTORE_PASS

if [ -f /etc/letsencrypt/live/$DOMAIN/$DOMAIN.p12 ]; then
	echo "Backing up UniFi keystore"
	cp /var/lib/unifi/keystore /var/lib/unifi/keystore.bak

	echo "Removing current UniFi certificate"
	keytool -delete -alias unifi -keystore /var/lib/unifi/keystore -storepass $KEYSTORE_PASS -noprompt

	echo "Importing Let's Encrypt $DOMAIN certificate"
	keytool -importkeystore -deststorepass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS -destkeystore /var/lib/unifi/keystore -srckeystore /etc/letsencrypt/live/$DOMAIN/$DOMAIN.p12 -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASS -alias unifi -noprompt

	echo "Restarting UniFi service"
	service unifi restart
else
   echo "An error has occured. The certificate was not generated. Please verify the Certbot/letsencrypt packages installed properly and that you have sufficient permission."
   echo "Refer to Certbot's documentation for errors generating certficates with your server and domain: https://certbot.eff.org/docs/"
fi
