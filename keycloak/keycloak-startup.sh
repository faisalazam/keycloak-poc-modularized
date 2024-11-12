#!/bin/sh

# I haven't tested this yet
# This is basically to run all the scripts at startup time,
# i.e. may be setting up smtp, ldap or any other such scripts etc.
# And then run this from docker-compose: entrypoint: ["/opt/keycloak-startup.sh"]

# Wait for Keycloak to be ready
until curl -s http://localhost:8080/health/ready; do
  echo "Waiting for Keycloak to be ready..."
  sleep 5
done

# Test SMTP integration
SMTP_TEST_RESULT=$(curl -s -X POST "http://localhost:8080/your-smtp-test-endpoint")
if echo "$SMTP_TEST_RESULT" | grep -q "success"; then
  echo "SMTP integration test passed."
else
  echo "SMTP integration test failed."
  exit 1
fi

# Test LDAP integration
LDAP_TEST_RESULT=$(curl -s -X GET "http://localhost:8080/your-ldap-test-endpoint")
if echo "$LDAP_TEST_RESULT" | grep -q "expected-ldap-response"; then
  echo "LDAP integration test passed."
else
  echo "LDAP integration test failed."
  exit 1
fi

# Start Keycloak
exec /opt/jboss/keycloak/bin/kc.sh start
