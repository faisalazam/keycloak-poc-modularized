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
    1. [Explanation of Key Variables](#explanation-of-key-variables)
        1. [PostgreSQL Settings](#postgresql-settings)
        2. [pgAdmin Settings](#pgadmin-settings)
        3. [Health Check Settings](#health-check-settings)
        4. [PgPass](#pgpass)
4. [Docker Compose Configuration](#docker-compose-configuration)
    1. [PostgreSQL Service](#postgresql-service)
    2. [pgAdmin Service](#pgadmin-service)
    3. [Healthcheck Explanation](#healthcheck-explanation)
    4. [Docker Bridge Network](#docker-bridge-network)
5. [Setup Instructions](#setup-instructions)
6. [Testing the Setup](#testing-the-setup)

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
  ├── postgres/
  │       ├── .env                         # Environment variables for Docker Compose
  │       ├── docker-compose.yml           # Docker Compose file for services
  │       ├── init_pgadmin.sh              # Script to initialize pgAdmin with custom settings
  │       ├── pgpass.template              # Template for pgpass file
  │       ├── servers.json.template        # Template for pgAdmin servers configuration
  │       ├── start.sh                     # Script to clean up and start services
  │       └── README.md                    # Project documentation (this file)
  └── startup_helper.sh                # Helper script for cleanup and service startup
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Environment Variables

Define the following environment variables in the `.env` file to customize PostgreSQL and pgAdmin services:

```plaintext
# PostgreSQL Settings
POSTGRES_DB=keycloak                  # Database name
POSTGRES_USER=keycloak                # PostgreSQL user
POSTGRES_PASSWORD=password            # Password for PostgreSQL user
POSTGRES_PORT=5433                    # Host port for PostgreSQL (maps to 5432 in container)
POSTGRES_INTERNAL_PORT=5432           # Internal PostgreSQL port
KEYCLOAK_DB_HOST_NAME=keycloak-db     # Container name for PostgreSQL

# pgAdmin Settings
PGADMIN_HTTP_PORT=5050                # Host port for pgAdmin (maps to 80 in container)
PGADMIN_HOST_NAME=pgadmin             # Container name for pgAdmin
PGADMIN_DEFAULT_EMAIL=user@gmail.com  # Default pgAdmin email
PGADMIN_DEFAULT_PASSWORD=admin        # Default pgAdmin password
PGADMIN_PASS_FILE="/var/lib/pgadmin/pgpass" # Path to the pgpass file in the container

## disables the pgadmin4 login screen.
PGADMIN_CONFIG_SERVER_MODE=False
## removes the need to enter the master password when the login screen is disabled
PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False

# Health Check Settings
HEALTHCHECK_INTERVAL=30s              # Time interval between health checks
HEALTHCHECK_TIMEOUT=10s               # Timeout duration for health checks
HEALTHCHECK_RETRIES=5                 # Number of retries for health checks
```
[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Explanation of Key Variables:

#### PostgreSQL Settings

- **POSTGRES_DB**: Specifies the name of the default database that PostgreSQL will create. In this setup, it's named
  `keycloak`.
- **POSTGRES_USER**: Defines the username for PostgreSQL access. This user has the necessary privileges to access and
  manage the specified database.
- **POSTGRES_PASSWORD**: Sets the password for the PostgreSQL user. This password should be kept secure, especially in
  production environments.
- **POSTGRES_PORT**: The port exposed on the host for PostgreSQL. It maps to PostgreSQL’s internal port (5432 by
  default) and allows host applications to connect.
- **POSTGRES_INTERNAL_PORT**: The internal port that PostgreSQL listens to within the container (usually 5432). It's
  mapped to `POSTGRES_PORT` on the host.
- **KEYCLOAK_DB_HOST_NAME**: The container name for the PostgreSQL service, allowing other containers (e.g., Keycloak)
  to refer to it using this hostname.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### pgAdmin Settings

- **PGADMIN_HTTP_PORT**: The port on the host for accessing pgAdmin’s web interface. It maps to port 80 within the
  pgAdmin container.
- **PGADMIN_HOST_NAME**: Sets the container name for the pgAdmin service, making it accessible by this name within the
  Docker network.
- **PGADMIN_DEFAULT_EMAIL**: The default email for logging into pgAdmin. Typically used as the pgAdmin administrator's
  email.
- **PGADMIN_DEFAULT_PASSWORD**: Password for logging into pgAdmin. This password is used alongside
  `PGADMIN_DEFAULT_EMAIL` to access the pgAdmin web interface.
- **PGADMIN_PASS_FILE**: The path where the pgAdmin password file (`pgpass`) will be stored. This file contains database
  connection information and should be securely configured.
- **PGADMIN_CONFIG_SERVER_MODE**: It disables the pgAdmin4 login screen, effectively running pgAdmin in "server mode".
  When set to False, pgAdmin4 does not require users to log in via the graphical user interface (GUI). **DO NOT DO THAT
  IN PROD**
- **PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED**: It removes the need to enter the master password when the login screen is
  disabled.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Health Check Settings

- **HEALTHCHECK_INTERVAL**: Sets the time interval between each health check for both PostgreSQL and pgAdmin. This
  ensures that Docker regularly verifies the health of these services.
- **HEALTHCHECK_TIMEOUT**: Specifies the maximum time allowed for a health check command to complete. If a check takes
  longer, it's marked as failed.
- **HEALTHCHECK_RETRIES**: Defines the number of retries for a service to pass health checks before it's marked as
  unhealthy. This can prevent intermittent issues from affecting the container’s health status.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### PgPass

The `pgpass` file is a plaintext file used to store connection credentials for PostgreSQL. The format for each line in
the `pgpass` file is as follows:

```makefile
hostname:port:database:username:password
```

It can have multiple such entries on new lines.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

##### Example

If your PostgreSQL database is named `keycloak-db`, hosted on `localhost`, with the username `keycloak` and password
`yourpassword`, the `pgpass` entry would look like this:

```
localhost:5432:keycloak-db:keycloak:yourpassword
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

###### Explanation of Fields

- **hostname**: The hostname of the PostgreSQL server (e.g., localhost, 127.0.0.1, or the service name defined in Docker
  Compose).
- **port**: The port number PostgreSQL is listening on (usually 5432).
- **database**: The name of the database to connect to (e.g., keycloak).
- **username**: The PostgreSQL username.
- **password**: The password associated with the username.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

###### Usage Notes

- **Location**: The `pgpass` file is usually located in the user's home directory (e.g., `~/.pgpass`) in Unix/Linux
  systems. In Docker, this path can be specified by `PGADMIN_PASS_FILE`.
- **Permissions**: For security, ensure that `pgpass` has restricted permissions (e.g., `chmod 0600 ~/.pgpass`),
  allowing only the file owner to read and write to it.

Using the `pgpass` file allows automatic password authentication when running commands with `psql` or connecting through
pgAdmin, simplifying secure access.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Docker Compose Configuration

In this section, we will detail each service in `docker-compose.yml` separately.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### PostgreSQL Service

The PostgreSQL service uses the official PostgreSQL
image ([PostgreSQL Docker Image](https://hub.docker.com/_/postgres)).

```yaml
services:
  postgres:
    image: postgres:17.0  # Specifies the Docker image to use for the PostgreSQL container (version 17.0).
    container_name: ${KEYCLOAK_DB_HOST_NAME}  # Container name is set using the environment variable for flexibility.
    env_file:
      - ./.env  # The .env file is used to load environment variables, such as database credentials and configuration.
    ports:
      - "${POSTGRES_PORT}:${POSTGRES_INTERNAL_PORT}"  # Exposes PostgreSQL's internal port to the specified external port.
    restart: unless-stopped  # Ensures the container is restarted unless it is manually stopped.
    healthcheck:
      test: [ "CMD", "pg_isready", "-U", "${POSTGRES_USER}" ]  # Runs the pg_isready command to check PostgreSQL readiness.
      interval: ${HEALTHCHECK_INTERVAL}  # Defines the interval between each health check.
      timeout: ${HEALTHCHECK_TIMEOUT}  # Sets the maximum time to wait for a response from the health check.
      retries: ${HEALTHCHECK_RETRIES}  # Specifies how many retries to attempt before considering the service unhealthy.
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Persistent storage for PostgreSQL data, ensuring data is retained between container restarts.
    networks:
      - keycloak_network  # Connects the container to a specified Docker network (used for communication with other services).
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

##### Explanation of Key Sections

- **image**: Specifies the PostgreSQL version.
- **container_name**: Uses the name from `.env` to make it easy to reference in other services.
- **env_file**: Reads in environment variables from the `.env` file.
- **ports**: Maps container port 5432 to 5433 on the host for PostgreSQL access.
- **healthcheck**: Uses `pg_isready` to confirm PostgreSQL is ready to accept connections.
- **restart**: Configures the container to restart automatically if it fails or stops unexpectedly.
- **volumes**: Persists data across container restarts.
- **networks**: Connects to a Docker bridge network for inter-container communication.

This setup ensures that your PostgreSQL service is properly configured, monitored, and connected to the necessary
network and resources.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### pgAdmin Service

The pgAdmin service uses the official pgAdmin image ([pgAdmin Docker Image](https://hub.docker.com/r/dpage/pgadmin4)).

```yaml
services:
  pgadmin:
    image: dpage/pgadmin4:8.12  # Specifies the Docker image for pgAdmin version 8.12.
    container_name: ${PGADMIN_HOST_NAME}  # The container name is dynamically set using an environment variable.
    env_file:
      - ./.env  # Loads environment variables from the .env file for configuration (e.g., ports, credentials).
    ports:
      - "${PGADMIN_HTTP_PORT}:80"  # Exposes pgAdmin's HTTP interface on the specified external port.
    volumes:
      - pgadmin_data:/var/lib/pgadmin  # Persistent storage for pgAdmin data (user settings, history, etc.).
      - ./init_pgadmin.sh:/init_pgadmin.sh  # Mounts a script to initialize pgAdmin when the container starts.
      - ./pgpass.template:/pgadmin4/pgpass.template  # Provides a template for the pgpass file (used for storing database login credentials securely).
      - ./servers.json.template:/pgadmin4/servers.json.template  # Mounts a template for pgAdmin's server configuration file.
    user: 'root'  # Runs the container as root user for executing the setup scripts.
    entrypoint: >  # Specifies the command to run inside the container when it starts.
      /bin/sh -c "
        echo 'Starting setup...';
        chmod +x /init_pgadmin.sh;  # Ensures the init_pgadmin.sh script is executable.
        /init_pgadmin.sh;  # Executes the script to initialize pgAdmin settings.
        cp -f /pgadmin4/pgpass /var/lib/pgadmin/;  # Copies the pgpass file to the pgAdmin data directory.
        chmod 600 /var/lib/pgadmin/pgpass;  # Sets proper permissions for the pgpass file.
        chown 5050:5050 /var/lib/pgadmin/pgpass;  # Ensures the pgpass file is owned by the pgAdmin user.
        chmod 600 /pgadmin4/servers.json;  # Sets proper permissions for the servers.json file.
        chown 5050:5050 /pgadmin4/servers.json;  # Ensures the servers.json file is owned by the pgAdmin user.
        /entrypoint.sh;  # Runs the default entrypoint to start pgAdmin after setup.
      "
    depends_on:
      postgres:
        condition: service_healthy  # Waits for the PostgreSQL service to be healthy before starting pgAdmin.
    networks:
      - keycloak_network  # Connects the container to the specified Docker network.
    healthcheck:
      test: [ "CMD", "nc", "-z", "localhost", "80" ]  # Checks if pgAdmin is running on port 80 (HTTP interface).
      interval: ${HEALTHCHECK_INTERVAL}  # The interval between health checks.
      timeout: ${HEALTHCHECK_TIMEOUT}  # Timeout for each health check.
      retries: ${HEALTHCHECK_RETRIES}  # Number of retries before marking the service as unhealthy.
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

##### Explanation of Key Sections

- **image**: Uses the `dpage/pgadmin4` Docker image with version 8.12 to run pgAdmin.
- **container_name**: Sets the container name based on the environment variable `PGADMIN_HOST_NAME` for easier
  identification.
- **env_file**: Loads environment variables from the `.env` file, which may include configuration options like ports,
  database connection details, etc.
- **ports**: Exposes pgAdmin's web interface on the port specified in the `.env` file (`PGADMIN_HTTP_PORT`).
- **volumes**:
    - `pgadmin_data`: Stores persistent data for pgAdmin.
    - `init_pgadmin.sh`: A script used to initialize pgAdmin with necessary configurations.
    - `pgpass.template`: A template for the pgAdmin `pgpass` file, which stores database login credentials securely.
    - `servers.json.template`: A template for the pgAdmin `servers.json` file, which stores information about the
      servers.
- **user**: Runs the container as the root user to allow for the execution of setup scripts.
- **entrypoint**: Customizes the startup process by:
    - Making the `init_pgadmin.sh` script executable.
    - Running the setup script.
    - Copying configuration files and adjusting permissions.
- **depends_on**: Ensures that the `postgres` service is healthy before pgAdmin starts.
- **networks**: Connects pgAdmin to the same Docker network as other services (e.g., PostgreSQL).
- **healthcheck**: Monitors the health of the pgAdmin container by checking if the HTTP service is responding on port 80.

This configuration sets up pgAdmin to run with the necessary initialization and security settings, including the
handling of database credentials with `pgpass` and server configurations with `servers.json`.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Healthcheck Explanation

##### PostgreSQL Health Check

The PostgreSQL health check uses `pg_isready`, a utility to check if PostgreSQL is ready to accept connections.

```yaml
healthcheck:
  test: [ "CMD", "pg_isready", "-U", "${POSTGRES_USER}" ]
  interval: ${HEALTHCHECK_INTERVAL:-30s}
  timeout: ${HEALTHCHECK_TIMEOUT:-10s}
  retries: ${HEALTHCHECK_RETRIES:-5}
```

For more details, refer to the [pg_isready Documentation](https://www.postgresql.org/docs/current/app-pgisready.html).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

##### pgAdmin Health Check

The pgAdmin health check uses nc (Netcat) to test if pgAdmin is running on port 80.

```yaml
healthcheck:
  test: [ "CMD", "nc", "-z", "localhost", "80" ]
  interval: ${HEALTHCHECK_INTERVAL:-30s}
  timeout: ${HEALTHCHECK_TIMEOUT:-10s}
  retries: ${HEALTHCHECK_RETRIES:-5}
```

For more details, refer to the [Netcat documentation](https://man7.org/linux/man-pages/man1/nc.1.html).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Docker Bridge Network

The Docker Bridge network is the default network mode for containers, providing secure communication between containers
on the same network while exposing only specified ports to the host. In this setup, both the PostgreSQL and pgAdmin
containers are connected to the `keycloak_network`, ensuring they can communicate with each other securely. By using the
bridge driver, the containers are isolated from the host network, providing an additional layer of security.

For more information on Docker networking, refer to
the [official Docker documentation on networking](https://docs.docker.com/network/).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Networks and Volumes

```yaml
networks:
  keycloak_network:
    driver: bridge          # Defines the bridge network for container communication
    name: keycloak_network

volumes:
  pgadmin_data:             # Volume for PgAdmin's data persistence
  postgres_data:            # Volume for PostgreSQL data persistence
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

##### Explanation:

- **networks.keycloak_network**: Uses the bridge driver to create an isolated network for secure inter-service
  communication. The Docker Bridge Network is Docker’s default networking mode for containers, which provides a private
  internal network where containers can communicate securely with one another. It also allows only specified ports to be
  exposed to the host.
- **volumes.postgres_data**: Ensures PostgreSQL data is retained across container restarts. This volume persists
  database data, preventing data loss if the PostgreSQL container is stopped or restarted.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Setup Instructions

- Clone the Repository and navigate to the postgres directory.
- Configure Environment Variables: Update .env as needed.
- Initialize and Start Services: Run the following to clean up any previous instances and start the services.

```bash
./start.sh
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Starting Services

To start all services, use the following command:

```bash
./start.sh
```

This will:

- Cleans up all containers, volumes, network before starting which are defined in the `docker-compose.yml` file.
- Start all the services defined in the `docker-compose.yml` file in detached mode (`-d`).
- Set up the PostgreSQL database and pgAdmin services.
- Connect all services through the defined `keycloak_network`.

You can also use:

```bash
docker compose up -d
```

To run each service individually if needed:

```bash
docker compose up -d postgres
docker compose up -d pgadmin
```

To re-build the image:

```bash
docker build -t custom-pgadmin -f Dockerfile.pgadmin .
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Stopping Services

To stop and remove the services:

```bash
docker compose down
```

#### Viewing Logs

To view logs for individual services:

```bash
docker compose logs -f postgres
docker compose logs -f pgadmin
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Testing the Setup

#### Access pgAdmin

1. Open a browser and go to [http://localhost:5050](http://localhost:5050).
2. Log in with the credentials specified in the `.env` file:

- **Email**: `PGADMIN_DEFAULT_EMAIL`
- **Password**: `PGADMIN_DEFAULT_PASSWORD`

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### Connect to PostgreSQL via pgAdmin

In pgAdmin, create a new server connection using the following details:

- **Host**: `keycloak-db` (matches `KEYCLOAK_DB_HOST_NAME`)
- **Port**: `5432`
- **Username**: `keycloak`
- **Password**: Value of `POSTGRES_PASSWORD`

But there is no need of this manual setup of Postgres server, as it'll be added automatically through `servers.json`:

```json
{
  "Servers": {
    "1": {
      "Group": "Servers",
      "SSLMode": "disable",
      "Name": "PostgreSQL",
      "SavePassword": true,
      "MaintenanceDB": "postgres",
      "Port": "{{PGADMIN_SERVER_PORT}}",
      "Host": "{{PGADMIN_SERVER_HOST}}",
      "Username": "{{PGADMIN_SERVER_USER}}",
      "PassFile": "{{PGADMIN_SERVER_PASS_FILE}}"
    }
  }
}
```

The `init_pgadmin.sh` will substitute that placeholders with their values.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Custom Scripts

- **init_pgadmin.sh**: Initializes `servers.json` and `pgpass` based on environment variables.
- **start.sh**: Starts services after cleanup by calling `../startup_helper.sh`.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)
