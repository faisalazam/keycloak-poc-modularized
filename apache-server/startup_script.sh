#!/bin/sh

if [ "$SETUP_KEYCLOAK_PROXY" = "true" ]; then
  echo "Define ENABLE_KEYCLOAK_PROXY" >> /usr/local/apache2/conf/extra/enable-keycloak.conf
else
  echo "" > /usr/local/apache2/conf/extra/enable-keycloak.conf
fi

# Start Apache
httpd-foreground