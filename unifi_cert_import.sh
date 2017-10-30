#!/bin/bash
##
## Author: David Griffin - https://github.com/Davie3
## Date: 10/30/17
## Title: UniFi Certificate Importer
## Description: A script for converting and importing a certificate into the UniFi controller's Java key store.
##              Assumes you already have a working version of the UniFi Controller installed.
## Requirements: UniFi - https://www.ubnt.com/download/unifi
## Disclaimer: Use at your own risk! Always make a backup of your UniFi install. It is very easy to restore a UniFi backup if something were to go wrong.
##

##Change the following variables accordingly:
CERT_LOCATION="/path/to/cert.pem" #Path to the certificate
KEY_LOCATION="/path/to/key.pem" #Path to the certificate's private key
CA_LOCATION="/path/to/chain.pem" #Path to the Intermediate certificate

KEYSTORE_PASS="aircontrolenterprise" #This is the default UniFi key store password.

##The following file will be generated. Specify where to store the pkcs12 export and what to name it (include the .p12 extension):
PKCS12_LOCATION="/path/to/domain.p12"

echo "Exporting $CERT_LOCATION with openssl"
openssl pkcs12 -export -in $CERT_LOCATION -inkey $KEY_LOCATION -out $PKCS12_LOCATION -name unifi -CAfile $CA_LOCATION -caname root -password pass:$KEYSTORE_PASS

if [ -f $PKCS12_LOCATION ]; then
	echo "Backing up UniFi keystore"
	cp /var/lib/unifi/keystore /var/lib/unifi/keystore.bak #Keep this safe if you ever have an issue!

	echo "Removing current UniFi certificate"
	keytool -delete -alias unifi -keystore /var/lib/unifi/keystore -storepass $KEYSTORE_PASS -noprompt

	echo "Importing Let's Encrypt $DOMAIN certificate"
	keytool -importkeystore -deststorepass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS -destkeystore /var/lib/unifi/keystore -srckeystore $PKCS12_LOCATION -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASS -alias unifi -noprompt

	echo "Restarting UniFi service"
	service unifi restart
else
   echo "An error has occured. The certificate was not exported. Please verify the certificate paths and check any errors with the openssl export."
fi
