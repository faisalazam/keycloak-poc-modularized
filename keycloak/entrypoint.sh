#!/bin/sh

# Testing it - if no reference found for this sh file, then delete it.

# Start Keycloak server in the background with realm import
/opt/keycloak/bin/kc.sh start-dev --import-realm &

# Function to check if Keycloak is ready using /dev/tcp method
wait_for_keycloak() {
  echo "Waiting for Keycloak to be ready..."
  while ! exec 3<>/dev/tcp/127.0.0.1/8080; do
    echo "Keycloak is not ready yet..."
    sleep 5
  done
  echo "Keycloak is up and ready!"
}

# Wait for Keycloak to be ready (do not proceed until this succeeds)
wait_for_keycloak

## Authenticate with Keycloak admin CLI
#/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin_password
#
## Refresh LDAP component (replace {LDAP_COMPONENT_ID} and {REALM} with actual values)
#/opt/keycloak/bin/kcadm.sh update components/{LDAP_COMPONENT_ID} -r {REALM} -s 'config.syncMode=["INHERIT"]'

# Wait to keep container running (optional if Keycloak is already started in background)
wait
