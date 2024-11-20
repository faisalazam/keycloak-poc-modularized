#!/bin/sh

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

# Get 'manage-users' role ID
get_manage_users_role_id() {
  realm=$1
  realm_mgmt_client_id=$2
  response=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$realm/clients/$realm_mgmt_client_id/roles" \
    -H "Authorization: Bearer $ACCESS_TOKEN")
  echo "$response" | jq -r '.[] | select(.name=="manage-users") | .id'
}

# Assign 'manage-users' role to service account
assign_manage_users_role() {
  realm=$1
  service_account_user_id=$2
  realm_mgmt_client_id=$3
  manage_users_role_id=$4

  curl -s -X POST "$KEYCLOAK_URL/admin/realms/$realm/users/$service_account_user_id/role-mappings/clients/$realm_mgmt_client_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "[{\"id\": \"$manage_users_role_id\", \"name\": \"manage-users\"}]"
  echo "'manage-users' role assigned to service account in realm '$realm'."
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

  REALM_CLIENT_PAIRS="ZenithRealm:zenith-user-mgmt-client QuantumRealm:quantum-user-mgmt-client"

  for pair in $REALM_CLIENT_PAIRS; do
    REALM=${pair%:*}
    CLIENT_ID=${pair#*:}

    if [ -z "$REALM" ] || [ -z "$CLIENT_ID" ]; then
      echo "Skipping due to empty realm or client ID."
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

    MANAGE_USERS_ROLE_ID=$(get_manage_users_role_id "$REALM" "$REALM_MGMT_CLIENT_ID")
    if [ -z "$MANAGE_USERS_ROLE_ID" ]; then
      echo "Failed to obtain MANAGE_USERS_ROLE_ID for realm '$REALM'."
      continue
    fi

    assign_manage_users_role "$REALM" "$SERVICE_ACCOUNT_USER_ID" "$REALM_MGMT_CLIENT_ID" "$MANAGE_USERS_ROLE_ID"
  done
}

main
