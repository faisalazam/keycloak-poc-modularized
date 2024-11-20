#!/bin/sh

# Wait for Keycloak to be ready.
until curl -s http://keycloak:9000/health/ready > /dev/null 2>&1; do
  echo "Waiting for Keycloak to be ready..."
  sleep 5
done

KEYCLOAK_URL="http://keycloak:8080"

# Obtain admin access token
TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "client_id=admin-cli" \
-d "username=${KC_BOOTSTRAP_ADMIN_USERNAME}" \
-d "password=${KC_BOOTSTRAP_ADMIN_PASSWORD}" \
-d "grant_type=password")

# Extract access token from response
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to obtain ACCESS_TOKEN."
#    echo "Token response: $TOKEN_RESPONSE"
    exit 1
fi

echo "ACCESS_TOKEN obtained successfully."

# Get the admin user ID
USER_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/master/users?username=${KC_BOOTSTRAP_ADMIN_USERNAME}" \
-H "Authorization: Bearer $ACCESS_TOKEN")

# Extract user ID from response
USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')

if [ -z "$USER_ID" ]; then
    echo "Failed to obtain USER_ID."
#    echo "User response: $USER_RESPONSE"
    exit 1
fi

#echo "USER_ID obtained: '$USER_ID'"

# Update the admin user's email - required particularly to test the SMTP connection
curl -s -X PUT "$KEYCLOAK_URL/admin/realms/master/users/$USER_ID" \
-H "Authorization: Bearer $ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
    "enabled": true,
    "email": "admin@example.com"
}'

echo "Updated the email for the '${KC_BOOTSTRAP_ADMIN_USERNAME}' user successfully."

# Define realms and client IDs as pairs (space-separated)
REALM_CLIENT_PAIRS="ZenithRealm:zenith-user-mgmt-client QuantumRealm:quantum-user-mgmt-client"

# Iterate over the realm/client ID pairs
for pair in $REALM_CLIENT_PAIRS ; do
  REALM=${pair%:*};
  CLIENT_ID=${pair#*:};

  # Check if both realm and client ID are not empty
  if [ -z "$REALM" ] || [ -z "$CLIENT_ID" ]; then
      echo "Skipping due to empty realm or client ID."
      continue
  fi

  # Get client info
  CLIENT_INFO_RESPONSE=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=$CLIENT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

  # Extract client UUID from response
  CLIENT_UUID=$(echo "$CLIENT_INFO_RESPONSE" | jq -r '.[0].id')

  if [ -z "$CLIENT_UUID" ]; then
      echo "Failed to obtain CLIENT_UUID for '$CLIENT_ID' in realm '$REALM'."
      continue
  fi

  echo "CLIENT_UUID obtained for '$CLIENT_ID' obtained successfully"

  # Get the service account user ID
  SERVICE_ACCOUNT_USER_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_UUID/service-account-user" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.id')

  if [ -z "$SERVICE_ACCOUNT_USER_ID" ]; then
      echo "Failed to obtain SERVICE_ACCOUNT_USER_ID for '$CLIENT_ID' in realm '$REALM'."
      continue
  fi

  echo "SERVICE_ACCOUNT_USER_ID for '$CLIENT_ID' obtained successfully"

  # Get the 'manage-users' role ID from the 'realm-management' client
  REALM_MGMT_CLIENT_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=realm-management" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[0].id')

  if [ -z "$REALM_MGMT_CLIENT_ID" ]; then
      echo "Failed to obtain REALM_MGMT_CLIENT_ID for realm '$REALM'."
      continue
  fi

  MANAGE_USERS_ROLE_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$REALM_MGMT_CLIENT_ID/roles" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[] | select(.name=="manage-users") | .id')

  if [ -z "$MANAGE_USERS_ROLE_ID" ]; then
      echo "Failed to obtain MANAGE_USERS_ROLE_ID for realm '$REALM'."
      continue
  fi

  echo "MANAGE_USERS_ROLE_ID obtained successfully"

  # Assign the 'manage-users' role to the service account
  curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users/$SERVICE_ACCOUNT_USER_ID/role-mappings/clients/$REALM_MGMT_CLIENT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\": \"$MANAGE_USERS_ROLE_ID\", \"name\": \"manage-users\"}]"

  echo "'manage-users' role assigned to service account of '$CLIENT_ID' in realm '$REALM'."
done
