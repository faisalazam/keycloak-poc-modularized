#!/bin/sh

# Default to ldap:// if not using TLS
if [ "$LDAP_TLS" = "true" ]; then
  LDAP_URL="ldaps://localhost:${LDAPS_PORT}"
else
  LDAP_URL="ldap://localhost:${LDAP_PORT}"
fi

if ldapsearch -H "$LDAP_URL" -x \
  -b "$LDAP_BASE_DN" \
  -D "cn=admin,$LDAP_BASE_DN" \
  -w "$LDAP_ADMIN_PASSWORD" > /dev/null 2>&1; then
  echo "✅ Connected to $LDAP_URL"
  exit 0
else
  echo "❌ Failed to connect to $LDAP_URL"
  exit 1
fi
