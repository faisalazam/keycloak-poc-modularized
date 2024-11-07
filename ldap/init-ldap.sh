#!/bin/sh

# Adding this shell script just because the ldif isn't getting imported automatically by the
# container startup, so, importing the ldif manually below.

# Start the LDAP server in the background
/container/tool/run &

# Wait for the LDAP server to be ready
while ! ldapsearch -x -b "$LDAP_BASE_DN" -D "$LDAP_BIND_DN" -w "$LDAP_ADMIN_PASSWORD" > /dev/null 2>&1; do
    echo "Waiting for LDAP to start..."
    sleep 2
done

# Import the LDIF file
ldapadd -x -D "$LDAP_BIND_DN" -w "$LDAP_ADMIN_PASSWORD" -f /container/service/slapd/assets/sample.ldif
echo "LDIF file imported."

# Keep the container running in the foreground
wait
