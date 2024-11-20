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
