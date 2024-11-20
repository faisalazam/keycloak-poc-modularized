#!/bin/sh

# If you face script not found error even though the script does exist, then it'll more likely be due to the fact that
# the script has CRLF line terminators (Windows-style). Run the following command to convert CRLF to LF to fix it:
# dos2unix keycloak/configure-keycloak.sh
# You can run the following to check the line terminators:
# file keycloak/configure-keycloak.sh
# If the output contains something like below, then it'd mean that it needs fixing to run on unix systems:
# ASCII text executable, with CRLF line terminators

KEYCLOAK_URL="http://keycloak:8080"

# Wait for Keycloak to be ready
wait_for_keycloak() {
  until curl -s http://keycloak:9000/health/ready > /dev/null 2>&1; do
    echo "Waiting for Keycloak to be ready..."
    sleep 5
  done
  echo "Keycloak is ready."
}

# Obtain admin access token
get_access_token() {
  response=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=admin-cli" \
    -d "username=${KC_BOOTSTRAP_ADMIN_USERNAME}" \
    -d "password=${KC_BOOTSTRAP_ADMIN_PASSWORD}" \
    -d "grant_type=password")
  echo "$response" | jq -r '.access_token'
}

# Get user ID by username
get_user_id() {
  username=$1
  response=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/master/users?username=$username" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$response" | jq -r '.[0].id'
}

# Update user email
update_user_email() {
  user_id=$1
  curl -s -X PUT "$KEYCLOAK_URL/admin/realms/master/users/$user_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "enabled": true,
        "email": "admin@example.com"
    }'
  echo "Updated email for '${KC_BOOTSTRAP_ADMIN_USERNAME}' successfully."
}

# Get client UUID by client ID
get_client_uuid() {
  realm=$1
  client_id=$2
  response=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$realm/clients?clientId=$client_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$response" | jq -r '.[0].id'
}

# Get service account user ID
get_service_account_user_id() {
  realm=$1
  client_uuid=$2
  response=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$realm/clients/$client_uuid/service-account-user" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$response" | jq -r '.id'
}

# Get 'realm-management' client ID
get_realm_management_client_id() {
  realm=$1
  response=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$realm/clients?clientId=realm-management" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$response" | jq -r '.[0].id'
}

# Get role ID by role name
get_role_id() {
  realm=$1
  realm_mgmt_client_id=$2
  role_name=$3
  response=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$realm/clients/$realm_mgmt_client_id/roles" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$response" | jq -r ".[] | select(.name==\"$role_name\") | .id"
}

# Assign role to service account
assign_role_to_service_account() {
  realm=$1
  service_account_user_id=$2
  realm_mgmt_client_id=$3
  role_id=$4
  role_name=$5

  curl -s -X POST "$KEYCLOAK_URL/admin/realms/$realm/users/$service_account_user_id/role-mappings/clients/$realm_mgmt_client_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "[{\"id\": \"$role_id\", \"name\": \"$role_name\"}]"
  echo "'$role_name' role assigned to service account in realm '$realm'."
}

# Main script logic
main() {
  wait_for_keycloak

  ACCESS_TOKEN=$(get_access_token)
  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to obtain ACCESS_TOKEN."
    exit 1
  fi
  echo "ACCESS_TOKEN obtained successfully."

  USER_ID=$(get_user_id "$KC_BOOTSTRAP_ADMIN_USERNAME")
  if [ -z "$USER_ID" ]; then
    echo "Failed to obtain USER_ID."
    exit 1
  fi

  update_user_email "$USER_ID"

  REALM_CLIENT_ROLE_PAIRS="
    zenithrealm:zenith-user-mgmt-client:manage-users
    zenithrealm:zenith-client-mgmt-client:manage-clients
    quantumrealm:quantum-user-mgmt-client:manage-users
    quantumrealm:quantum-client-mgmt-client:manage-clients"

  for pair in $REALM_CLIENT_ROLE_PAIRS; do
    REALM=$(echo "$pair" | cut -d':' -f1)
    CLIENT_ID=$(echo "$pair" | cut -d':' -f2)
    ROLE_NAME=$(echo "$pair" | cut -d':' -f3)

    if [ -z "$REALM" ] || [ -z "$CLIENT_ID" ] || [ -z "$ROLE_NAME" ]; then
      echo "Skipping due to empty realm, client ID, or role name."
      continue
    fi

    CLIENT_UUID=$(get_client_uuid "$REALM" "$CLIENT_ID")
    if [ -z "$CLIENT_UUID" ]; then
      echo "Failed to obtain CLIENT_UUID for '$CLIENT_ID' in realm '$REALM'."
      continue
    fi

    SERVICE_ACCOUNT_USER_ID=$(get_service_account_user_id "$REALM" "$CLIENT_UUID")
    if [ -z "$SERVICE_ACCOUNT_USER_ID" ]; then
      echo "Failed to obtain SERVICE_ACCOUNT_USER_ID for '$CLIENT_ID' in realm '$REALM'."
      continue
    fi

    REALM_MGMT_CLIENT_ID=$(get_realm_management_client_id "$REALM")
    if [ -z "$REALM_MGMT_CLIENT_ID" ]; then
      echo "Failed to obtain REALM_MGMT_CLIENT_ID for realm '$REALM'."
      continue
    fi

    ROLE_ID=$(get_role_id "$REALM" "$REALM_MGMT_CLIENT_ID" "$ROLE_NAME")
    if [ -z "$ROLE_ID" ]; then
      echo "Failed to obtain ROLE_ID for role '$ROLE_NAME' in realm '$REALM'."
      continue
    fi

    assign_role_to_service_account "$REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MGMT_CLIENT_ID" "$ROLE_ID" "$ROLE_NAME"
  done
}

main
