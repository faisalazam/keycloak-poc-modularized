#!/bin/sh

# Default to ldap:// if not using TLS
if [ "$LDAP_ENABLE_TLS" = "yes" ]; then
  LDAP_URL="${LDAPS_URL}"
#else
  # LDAP_URL="${LDAP_URL}" # Already set in .env file
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
