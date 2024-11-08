# PostgreSQL and pgAdmin Setup with Docker

This guide provides a comprehensive setup for **PostgreSQL** and **pgAdmin** using Docker, which allows for easy
management and administration of databases in a local development environment. This setup can be beneficial for
developers who want to work with a robust database without installing it directly on their systems. Docker Compose makes
the setup straightforward, and environment variables ensure it is easily configurable.

### Why Use PostgreSQL and pgAdmin?

- **[PostgreSQL](https://www.postgresql.org/)** is an advanced, enterprise-class open-source relational database known
  for its robustness, extensibility, and SQL compliance. It is suitable for handling complex queries and managing large
  amounts of data, making it ideal for development and production environments.
- **[pgAdmin](https://www.pgadmin.org/)** is a feature-rich web-based administration tool for PostgreSQL, allowing users
  to manage databases with a GUI, simplifying tasks such as creating tables, managing users, and querying data. It’s
  particularly useful when working with multiple databases.

This guide also includes health checks and networking tips for reliable service management, leveraging Docker’s bridge
network for secure inter-container communication.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Directory Structure](#directory-structure)
3. [Environment Variables](#environment-variables)
4. [Docker Compose Configuration](#docker-compose-configuration)
5. [Setup Instructions](#setup-instructions)
6. [Testing the Setup](#testing-the-setup)
7. [Healthcheck Explanation](#healthcheck-explanation)
8. [Docker Bridge Network](#docker-bridge-network)

---

## Prerequisites

Ensure Docker and Docker Compose are installed on your system:

- [Install Docker](https://docs.docker.com/get-docker/)
- [Install Docker Compose](https://docs.docker.com/compose/install/)

---

## Directory Structure

Your project directory should look like this:

```plaintext
project-root/
    └── postgres
          ├── .env                       # Environment variables for Docker Compose
          ├── docker-compose.yml         # Docker Compose file to spin up services
          └── README.md                  # Project documentation (this file)
```

### Environment Variables

Define the following environment variables in the `.env` file to customize PostgreSQL and pgAdmin services:

```plaintext
# PostgreSQL Database Settings
POSTGRES_DB=keycloak                    # Name of the PostgreSQL database
POSTGRES_USER=keycloak                  # PostgreSQL user with permissions
POSTGRES_PASSWORD=password              # Password for the PostgreSQL user
KEYCLOAK_DB_HOST_NAME=keycloak-db       # Hostname for the PostgreSQL container

# pgAdmin Settings
PGADMIN_HOST_NAME=pgadmin               # Hostname for the pgAdmin container
PGADMIN_DEFAULT_EMAIL=user@gmail.com    # Login email for pgAdmin
PGADMIN_DEFAULT_PASSWORD=admin          # Login password for pgAdmin

# Healthcheck settings
HEALTHCHECK_INTERVAL=30s                # Time interval between healthcheck attempts
HEALTHCHECK_TIMEOUT=10s                 # Healthcheck timeout duration
HEALTHCHECK_RETRIES=5                   # Healthcheck retry count
```

### Explanation of Key Variables:

- **POSTGRES_DB** and **POSTGRES_USER**: Define the database name and the user with permissions to access it.
- **KEYCLOAK_DB_HOST_NAME**: Used by pgAdmin to connect to the PostgreSQL container.
- **HEALTHCHECK\_*** variables: Configure healthcheck frequency, duration, and retry count to ensure services are fully
  ready before connections are established.

### Docker Compose Configuration

In this section, we will detail each service in `docker-compose.yml` separately.

#### PostgreSQL Service

The PostgreSQL service uses the official PostgreSQL
image ([PostgreSQL Docker Image](https://hub.docker.com/_/postgres)).

```yaml
services:
  postgres:
    image: postgres:17.0
    container_name: ${KEYCLOAK_DB_HOST_NAME}       # Sets the container name from the .env variable
    env_file:
      - ./.env                                      # Imports environment variables from .env
    ports:
      - "5433:5432"                                 # Maps host port 5433 to container port 5432
    restart: unless-stopped                         # Restarts the container unless explicitly stopped
    healthcheck:
      test: [ "CMD", "pg_isready", "-U", "${POSTGRES_USER}" ]
      interval: ${HEALTHCHECK_INTERVAL:-30s}        # Healthcheck interval from .env file
      timeout: ${HEALTHCHECK_TIMEOUT:-10s}          # Healthcheck timeout duration
      retries: ${HEALTHCHECK_RETRIES:-5}            # Healthcheck retry count
    volumes:
      - postgres_data:/var/lib/postgresql/data      # Persistent storage for database data
    networks:
      - keycloak_network
```

### Explanation:

- **image**: Specifies the PostgreSQL version.
- **container_name**: Uses the name from `.env` to make it easy to reference in other services.
- **env_file**: Reads in environment variables from the `.env` file.
- **ports**: Maps container port 5432 to 5433 on the host for PostgreSQL access.
- **healthcheck**: Uses `pg_isready` to confirm PostgreSQL is ready to accept connections.
- **volumes**: Persists data across container restarts.
- **networks**: Connects to a Docker bridge network for inter-container communication.

### pgAdmin Service

The pgAdmin service uses the official pgAdmin image ([pgAdmin Docker Image](https://hub.docker.com/r/dpage/pgadmin4)).

```yaml
  pgadmin:
    image: dpage/pgadmin4:8.12
    container_name: ${PGADMIN_HOST_NAME}            # Container name from .env variable
    env_file:
      - ./.env                                      # Imports environment variables from .env
    ports:
      - "5050:80"                                   # Maps host port 5050 to container port 80
    depends_on:
      postgres:
        condition: service_healthy                  # Waits for PostgreSQL to be healthy before starting
    networks:
      - keycloak_network
    healthcheck:
      test: [ "CMD", "nc", "-z", "localhost", "80" ]
      interval: ${HEALTHCHECK_INTERVAL:-30s}        # Healthcheck interval from .env file
      timeout: ${HEALTHCHECK_TIMEOUT:-10s}          # Healthcheck retry count
```

### Explanation:

- **image**: Specifies the pgAdmin image and version.
- **container_name**: Sets the container name for easier reference.
- **depends_on**: Ensures pgAdmin only starts when PostgreSQL is ready.
- **healthcheck**: Uses `nc` (Netcat) to check if pgAdmin is running on port 80.
- **networks**: Uses the same network as PostgreSQL, enabling communication between the two services.

### Networks and Volumes

```yaml
networks:
  keycloak_network:
    driver: bridge                                 # Defines the bridge network for container communication
    name: keycloak_network

volumes:
  postgres_data:                                   # Volume for PostgreSQL data persistence
```

### Explanation:

- **networks.keycloak_network**: Uses the bridge driver to create an isolated network for secure inter-service
  communication. The Docker Bridge Network is Docker’s default networking mode for containers, which provides a private
  internal network where containers can communicate securely with one another. It also allows only specified ports to be
  exposed to the host.

- **volumes.postgres_data**: Ensures PostgreSQL data is retained across container restarts. This volume persists
  database data, preventing data loss if the PostgreSQL container is stopped or restarted.

### Setup Instructions

#### Starting Services

To start all services, use the following command:

```bash
docker-compose up -d
```

This will:

- Start all the services defined in your `docker-compose.yml` file in detached mode (`-d`).
- Set up the PostgreSQL database and pgAdmin services.
- Connect all services through the defined `keycloak_network`.

To run each service individually if needed:

```bash
docker-compose up -d postgres
docker-compose up -d pgadmin
```

## Stopping Services

To stop and remove the services:

```bash
docker-compose down
```

## Viewing Logs

To view logs for individual services:

```bash
docker-compose logs -f postgres
docker-compose logs -f pgadmin
```

## Testing the Setup

### Access pgAdmin

1. Open a browser and go to [http://localhost:5050](http://localhost:5050).
2. Log in with the credentials specified in the `.env` file:

- **Email**: `PGADMIN_DEFAULT_EMAIL`
- **Password**: `PGADMIN_DEFAULT_PASSWORD`

### Connect to PostgreSQL via pgAdmin

In pgAdmin, create a new server connection using the following details:

- **Host**: `keycloak-db` (matches `KEYCLOAK_DB_HOST_NAME`)
- **Port**: `5432`
- **Username**: `keycloak`
- **Password**: Value of `POSTGRES_PASSWORD`

### Healthcheck Explanation

#### PostgreSQL Health Check

The PostgreSQL health check uses `pg_isready`, a utility to check if PostgreSQL is ready to accept connections.

```yaml
healthcheck:
  test: [ "CMD", "pg_isready", "-U", "${POSTGRES_USER}" ]
  interval: ${HEALTHCHECK_INTERVAL:-30s}
  timeout: ${HEALTHCHECK_TIMEOUT:-10s}
  retries: ${HEALTHCHECK_RETRIES:-5}
```

For more details, refer to the [pg_isready Documentation](https://www.postgresql.org/docs/current/app-pgisready.html).

pgAdmin Health Check
The pgAdmin health check uses nc (Netcat) to test if pgAdmin is running on port 80.

```yaml
healthcheck:
  test: [ "CMD", "nc", "-z", "localhost", "80" ]
  interval: ${HEALTHCHECK_INTERVAL:-30s}
  timeout: ${HEALTHCHECK_TIMEOUT:-10s}
  retries: ${HEALTHCHECK_RETRIES:-5}
```

For more details, refer to the [Netcat documentation](https://man7.org/linux/man-pages/man1/nc.1.html).

### Docker Bridge Network

The Docker Bridge network is the default network mode for containers, providing secure communication between containers
on the same network while exposing only specified ports to the host. In this setup, both the PostgreSQL and pgAdmin
containers are connected to the `keycloak_network`, ensuring they can communicate with each other securely. By using the
bridge driver, the containers are isolated from the host network, providing an additional layer of security.

For more information on Docker networking, refer to
the [official Docker documentation on networking](https://docs.docker.com/network/).

