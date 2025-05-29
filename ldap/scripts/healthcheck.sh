#!/bin/sh

# Default to ldap:// if not using TLS
if [ "$LDAP_ENABLE_TLS" = "yes" ]; then
  LDAP_CONNECTION_URL="${LDAPS_URL}"
else
  LDAP_CONNECTION_URL="${LDAP_URL}"
fi

echo "→ Connecting to $LDAP_CONNECTION_URL"

if ldapsearch -H "$LDAP_CONNECTION_URL" -x \
  -b "$LDAP_BASE_DN" \
  -D "cn=admin,$LDAP_BASE_DN" \
  -w "$LDAP_ADMIN_PASSWORD" > /dev/null 2>&1; then
  echo "✅ Connected to $LDAP_CONNECTION_URL"
  exit 0
else
  echo "❌ Failed to connect to $LDAP_CONNECTION_URL"
  exit 1
fi
