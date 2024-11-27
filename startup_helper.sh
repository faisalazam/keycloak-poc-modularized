#!/bin/sh

handle_error() {
    echo "Error: $1"
    exit 1
}

# Function to clean up containers, volumes, and networks, then start services
cleanup_and_start() {
    echo "Starting cleanup process..."

    # Stop and remove containers and volumes specific to this compose file
    echo "Stopping and removing containers and volumes for the current stack..."
    docker-compose down --volumes --remove-orphans || handle_error "Failed to stop and remove containers/volumes"

    # Remove the networks created by Docker Compose
    echo "Removing networks..."

    # Get the network ID for networks created by the Compose file (match the prefix or name)
    NETWORK_NAME=keycloak_network
    NETWORK_ID=$(docker network ls --filter "name=${NETWORK_NAME}" -q)

    # If network exists, remove it
    if [ -n "$NETWORK_ID" ]; then
        docker network rm "$NETWORK_ID" || handle_error "Failed to remove network: $NETWORK_ID"
    else
        echo "No networks found with the name ${NETWORK_NAME}. Skipping network removal."
    fi

    if [ "$EXPOSE_KEYCLOAK_TO_HOST_ONLY" = "true" ]; then
      echo "Running 'docker-compose up -d' to start the services with overrides..."
      docker-compose -f docker-compose.yml -f override.yml up -d || handle_error "Failed to bring up services using docker-compose up"
    else
      echo "Running 'docker-compose up -d' to start the services without overrides..."
      docker-compose -f docker-compose.yml up -d || handle_error "Failed to bring up services using docker-compose up"
    fi

    echo "Services have been started successfully!"
}
