#!/bin/sh

# I haven't tested this yet

# Function to check SMTP integration
check_smtp() {
    echo "Checking SMTP integration..."
    # Use curl or nc to check if SMTP is reachable
    if echo "EHLO test" | nc -w 5 mailhog 1025; then
        echo "SMTP is reachable."
    else
        echo "SMTP is not reachable!"
        exit 1
    fi

    # Attempt to trigger an email
    # Here you would add code to create a user and trigger an email in Keycloak
    # This is an example and should be adjusted to your API and configuration
    RESPONSE=$(curl -s -X POST http://keycloak:8080/auth/admin/realms/QuantumRealm/users -H "Content-Type: application/json" -d '{
        "username": "testuser",
        "email": "testuser@example.com",
        "enabled": true,
        "firstName": "Test",
        "lastName": "User",
        "credentials": [{"type": "password", "value": "password", "temporary": false}]
    }')

    if [ "$?" -ne 0 ]; then
        echo "Failed to create test user!"
        exit 1
    fi

    # Here you would typically trigger the email, e.g., by resetting the password or verifying the email
    echo "Test user created. Check MailHog for email delivery."
}

# Function to check LDAP integration
check_ldap() {
    echo "Checking LDAP integration..."
    # This check can be more complex; it may involve querying the Keycloak API for users
    # You may need to adjust the following command based on your setup

    LDAP_USERS=$(curl -s -X GET "http://keycloak:8080/auth/admin/realms/QuantumRealm/users" -H "Content-Type: application/json")

    if echo "$LDAP_USERS" | grep -q "your_ldap_username"; then
        echo "LDAP is integrated successfully."
    else
        echo "LDAP integration failed!"
        exit 1
    fi
}

# Main script execution
check_smtp
check_ldap

echo "Keycloak integration with SMTP and LDAP is successful."
exit 0
