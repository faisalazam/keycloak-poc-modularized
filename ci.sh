#!/bin/sh

# Source the helper script to access the cleanup_and_start function
. ./startup_helper.sh

# Call the function to clean up and start the services
EXPOSE_KEYCLOAK_TO_HOST_ONLY=true cleanup_and_start
