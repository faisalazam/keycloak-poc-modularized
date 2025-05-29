#!/bin/sh

# Dynamically set the correct LDAP host
if [ "$LDAP_ENABLE_TLS" = "yes" ]; then
  export PHPLDAPADMIN_LDAP_HOSTS="$LDAPS_URL"
else
  export PHPLDAPADMIN_LDAP_HOSTS="$LDAP_URL"
fi

# Call original entrypoint
exec /container/tool/run
