#!/bin/sh

# Determine correct URL (with or without TLS)
if [ "$LDAP_ENABLE_TLS" = "yes" ]; then
  LDAP_CONNECTION_URL="$LDAPS_URL"
else
  LDAP_CONNECTION_URL="$LDAP_URL"
fi

echo "→ Connecting to $LDAP_CONNECTION_URL"

# Check connection and bind success
if ! ldapsearch -H "$LDAP_CONNECTION_URL" -x \
  -b "$LDAP_BASE_DN" \
  -D "cn=admin,$LDAP_BASE_DN" \
  -w "$LDAP_ADMIN_PASSWORD" \
  -s base "(objectClass=*)" > /dev/null 2>&1; then
  echo "❌ Failed to connect or bind to $LDAP_CONNECTION_URL"
  exit 1
fi

echo "✅ Connected and bound to $LDAP_CONNECTION_URL"

# Check for known entry from LDIF to ensure import succeeded (e.g. uid=user5)
TEST_USER_DN="uid=user5,ou=users,$LDAP_BASE_DN"

if ldapsearch -H "$LDAP_CONNECTION_URL" -x \
  -w "$LDAP_ADMIN_PASSWORD" \
  -D "cn=admin,$LDAP_BASE_DN" \
  -b "$TEST_USER_DN" "(objectClass=inetOrgPerson)" > /dev/null 2>&1; then
  echo "✅ Found test user: $TEST_USER_DN"
  exit 0
else
  echo "⚠️  Connected but test user not found: $TEST_USER_DN"
  exit 2
fi
