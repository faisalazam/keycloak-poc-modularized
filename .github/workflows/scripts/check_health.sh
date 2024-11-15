#!/bin/sh
# Set the timeout duration to 100 seconds for the health check
if ! timeout 100s sh -c '
  until curl -s http://localhost:9000/health/ready | grep -q "\"status\": \"UP\""; do
    echo "Waiting for service to start..."
    sleep 5
  done
'; then
    echo "Service health check timed out."
    exit 1
fi

echo "Service is up and healthy."
