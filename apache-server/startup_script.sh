#!/bin/sh

if [ "$SETUP_KEYCLOAK_PROXY" = "true" ]; then
  echo "Define ENABLE_KEYCLOAK_PROXY" >> /usr/local/apache2/conf/extra/enable-keycloak.conf
  echo "SUCCESS: ENABLE_KEYCLOAK_PROXY defined in enable-keycloak.conf"
else
  echo "" > /usr/local/apache2/conf/extra/enable-keycloak.conf
  echo "SUCCESS: Cleared enable-keycloak.conf as SETUP_KEYCLOAK_PROXY is not true"
fi

# Start Apache
httpd-foreground