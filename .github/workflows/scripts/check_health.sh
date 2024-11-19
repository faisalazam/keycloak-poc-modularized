#!/bin/sh
# Set the timeout duration to 100 seconds for the health check
if ! timeout 100s sh -c '
  until docker exec <container_name> sh -c "
    exec 3<>/dev/tcp/127.0.0.1/9000 &&
    echo -e \"GET /health/ready HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n\" >&3 &&
    grep -q \"\\\"status\\\": \\\"UP\\\"\" <&3
  "; do
    echo "Waiting for service to start inside the container..."
    sleep 5
  done
'; then
    echo "Service health check timed out."
    exit 1
fi

echo "Service is up and healthy."
