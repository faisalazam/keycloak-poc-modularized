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

    echo "Running 'docker-compose up -d' to start the services..."

    ls -lart .
    ls -lart ../ldap
    ls -lart ../postgres


    # Run the docker-compose up command
    docker-compose up -d || handle_error "Failed to bring up services using docker-compose up"
    # docker-compose -f docker-compose.yml -f ./../ldap/docker-compose.yml -f ./../mailhog/docker-compose.yml -f ./../postgres/docker-compose.yml up || handle_error "Failed to bring up services using docker-compose up"

    echo "Services have been started successfully!"
}
