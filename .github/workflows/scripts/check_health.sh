#!/bin/sh
# Set the timeout duration
timeout 100s sh -c '
  until curl -s http://localhost:9000/health/ready | grep -q "\"status\": \"UP\""; do
    echo "Waiting for service to start..."
    sleep 5
  done
'

# Check exit code for timeout
if [ $? -ne 0 ]; then
    echo "Service health check timed out."
    exit 1
fi
echo "Service is up and healthy."
