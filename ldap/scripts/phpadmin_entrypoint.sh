#!/bin/sh

# Dynamically set the correct LDAP host
if [ "$LDAP_ENABLE_TLS" = "yes" ]; then
  LDAP_CONNECTION_URL="${LDAPS_URL}"
else
  LDAP_CONNECTION_URL="${LDAP_URL}"
fi

export PHPLDAPADMIN_LDAP_HOSTS="$LDAP_CONNECTION_URL"

# Call original entrypoint
exec /container/tool/run
