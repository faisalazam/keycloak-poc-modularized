# Keycloak Setup for Modularized Project

## Introduction

This folder contains the setup and configuration files for running **Keycloak** in a modularized environment using
Docker Compose. The setup integrates Keycloak with PostgreSQL, and imports realms for different environments.

Keycloak is an open-source identity and access management solution, designed for modern applications and services. It
provides features like Single Sign-On (SSO), user federation, identity brokering, and social login.

For official documentation on Keycloak, refer to the links below:

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak GitHub Repository](https://github.com/keycloak/keycloak)

---

## Table of Contents

- [Project Structure](#project-structure)
- [Clone the Repository](#clone-the-repository)
- [Environment Variables](#environment-variables)
- [Docker Compose Setup](#docker-compose-setup)
    - [Services](#services)
        1. [1. `realm-setup` Service](#1-realm-setup-service)
        2. [2. `keycloak` Service](#2-keycloak-service)
        3. [3. `keycloak_setup` Service](#3-keycloak_setup-service)
- [Starting the Services](#starting-the-services)
- [Keycloak Realm Setup](#keycloak-realm-setup)
- [Conclusion](#conclusion)

---

## Project Structure

```plaintext
keycloak-poc-modularized
 └── keycloak
     ├── configure-keycloak.sh
     ├── docker-compose.yml
     ├── prepare_realm_exports.sh
     ├── realms
     │   ├── quantum
     │   │   ├── ldap.json
     │   │   ├── realm-export.json
     │   │   ├── smtp.json
     │   │   └── users.json
     │   ├── zenith
     │   │   ├── ldap.json
     │   │   ├── realm-export.json
     │   │   ├── smtp.json
     │   │   └── users.json
     │   └── README.md
     ├── start.sh
     └── README.md
```

---

## Clone the Repository

To get started, clone the repository using the following command:

```bash
git clone https://github.com/faisalazam/keycloak-poc-modularized.git
```

---

## Environment Variables

The .env file contains important configuration settings for PostgreSQL, Keycloak, LDAP, and SMTP services. These
environment variables help configure the services in a flexible manner, making the setup easily customizable for
different environments.

Example .env file:

```ini
# PostgreSQL Settings
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=password

# Keycloak Settings
KEYCLOAK_PORT=8080
KEYCLOAK_MANAGEMENT_PORT=9000
KC_DB=postgres
KC_DB_URL_HOST=postgres
KC_DB_URL_DATABASE=${POSTGRES_DB}
KC_DB_USERNAME=${POSTGRES_USER}
KC_DB_PASSWORD=${POSTGRES_PASSWORD}
KC_BOOTSTRAP_ADMIN_USERNAME=admin
KC_BOOTSTRAP_ADMIN_PASSWORD=admin

# Health Check Settings
KC_HEALTH_ENABLED=true
KEYCLOAK_HEALTHCHECK_INTERVAL=30s
KEYCLOAK_HEALTHCHECK_TIMEOUT=10s
KEYCLOAK_HEALTHCHECK_RETRIES=5

# LDAP Configuration
SETUP_LDAP=true
LDAP_URL=ldap://openldap:389
LDAP_BIND_DN=cn=admin,dc=example,dc=com
LDAP_BIND_CREDENTIAL=ldap_admin_password
LDAP_USERS_DN=ou=users,dc=example,dc=com

# SMTP Configuration
SETUP_SMTP=true
SMTP_AUTH=false
SMTP_PORT=1025
SMTP_HOST=mailhog
SMTP_STARTTLS=false
SMTP_ENCRYPTION=none
SMTP_USER=smtp_user
SMTP_PASSWORD=smtp_password
SMTP_FROM_DISPLAY_NAME=Support
SMTP_FROM=no-reply@example.org
SMTP_REPLY_TO=no-reply@example.org
```

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

### Explanation of Key Environment Variables:

#### PostgreSQL Settings:

- **POSTGRES_DB**: Name of the PostgreSQL database used by Keycloak.
- **POSTGRES_USER**: Username for the PostgreSQL database.
- **POSTGRES_PASSWORD**: Password for the PostgreSQL database.

#### Keycloak Settings:

- **KEYCLOAK_PORT**: Port on which Keycloak will run (default is 8080).
- **KEYCLOAK_MANAGEMENT_PORT**: Port for Keycloak's management console (default is 9000).
- **KC_DB**: Database type to use with Keycloak, set to postgres for PostgreSQL.
- **KC_DB_URL_HOST**: Hostname for the PostgreSQL database.
- **KC_DB_URL_DATABASE**: Database name used by Keycloak.
- **KC_DB_USERNAME**: Username for connecting to PostgreSQL.
- **KC_DB_PASSWORD**: Password for connecting to PostgreSQL.
- **KC_BOOTSTRAP_ADMIN_USERNAME** and **KC_BOOTSTRAP_ADMIN_PASSWORD**: Admin credentials for Keycloak after setup.

#### Health Check Settings:

- **KC_HEALTH_ENABLED**: Enable health checks for Keycloak.
- **KEYCLOAK_HEALTHCHECK_INTERVAL**: How often health checks are performed (e.g., 30s).
- **KEYCLOAK_HEALTHCHECK_TIMEOUT**: Timeout duration for health checks (e.g., 10s).
- **KEYCLOAK_HEALTHCHECK_RETRIES**: Number of retries for health checks.

#### LDAP Configuration:

- **SETUP_LDAP**: Set to true to enable LDAP integration.
- **LDAP_URL**: URL of the LDAP server.
- **LDAP_BIND_DN**: Distinguished Name (DN) for binding to the LDAP server.
- **LDAP_BIND_CREDENTIAL**: Password for the bind DN.
- **LDAP_USERS_DN**: DN to use for querying users.

#### SMTP Configuration:

- **SETUP_SMTP**: Set to true to enable SMTP configuration.
- **SMTP_AUTH**: Whether authentication is required for SMTP (default is false).
- **SMTP_PORT**: Port for the SMTP server.
- **SMTP_HOST**: Host for the SMTP server (default is MailHog in this setup).
- **SMTP_STARTTLS**: Whether to use STARTTLS for secure communication (default is false).
- **SMTP_ENCRYPTION**: Type of encryption for SMTP (none or starttls).
- **SMTP_USER**, **SMTP_PASSWORD**: SMTP credentials.
- **SMTP_FROM_DISPLAY_NAME**: The display name for the "From" field in emails.
- **SMTP_FROM** and **SMTP_REPLY_TO**: The email addresses for sending and replying to emails.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Docker Compose Setup

### Services

The `docker-compose.yml` file defines the services that make up the Keycloak infrastructure.

#### 1. `realm-setup` Service

- **Purpose**: This service generates the realm-export.json files used by Keycloak.
- **Image**: alpine:3.16
- **Dependencies**: Requires environment variables and realm files to be passed.
- **Volumes**: Realm files are stored in `./realms` and shared with Keycloak.

```yaml
realm-setup:
  image: alpine:3.16
  container_name: realm-export-generator
  env_file:
    - ./.env
  volumes:
    - ./realms:/tmp/realms
    - ./prepare_realm_exports.sh:/tmp/prepare_realm_exports.sh
    - keycloak_data:/shared
  networks:
    - keycloak_network
  entrypoint:
    - /bin/sh
    - -c
    - |
      apk add --no-cache gettext jq && \
      chmod +x /tmp/prepare_realm_exports.sh && \
      /tmp/prepare_realm_exports.sh
```

##### realm-setup Service Explanation

The `realm-setup` service in the provided Docker Compose snippet is responsible for preparing realm configuration files
for Keycloak. Here's an explanation of each part:

###### `image: alpine:3.16`

- **alpine:3.16**: This specifies the Docker image to use for the container. `alpine` is a lightweight Linux
  distribution, and `3.16` is the version being used here.

###### `container_name: realm-export-generator`

- **container_name**: This gives the container a specific name (`realm-export-generator`), making it easier to refer to
  in Docker commands and logs.

###### `env_file:`

- **env_file**: The `env_file` option loads environment variables from the specified `.env` file. The environment
  variables defined in this file will be available inside the container. This is used to set configuration values for
  services like PostgreSQL, Keycloak, LDAP, etc.

###### `volumes:`

- **./realms:/tmp/realms**: This mounts the `./realms` directory from the host machine to `/tmp/realms` inside the
  container. It allows the container to read and write to the `realms` directory in the project.
- **./prepare_realm_exports.sh:/tmp/prepare_realm_exports.sh**: This mounts the `prepare_realm_exports.sh` script from
  the host to the container, allowing it to be executed inside the container.
- **keycloak_data:/shared**: This creates a Docker volume named `keycloak_data` and mounts it to `/shared` inside the
  container. This volume is used for persisting data related to Keycloak.

###### `networks:`

- **keycloak_network**: The container is attached to the `keycloak_network`, which is a Docker network used to allow
  communication between different services in the same network (e.g., Keycloak, PostgreSQL).

###### `entrypoint:`

The `entrypoint` defines the commands that will be run when the container starts.

- `/bin/sh -c`: This runs the shell (`/bin/sh`) with the `-c` option to execute a command passed as a string.
- The commands inside the string are:
    - **apk add --no-cache gettext jq**: Installs the `gettext` and `jq` packages in the container. `gettext` is a
      library used for internationalization, and `jq` is a lightweight and flexible command-line JSON processor.
    - **chmod +x /tmp/prepare_realm_exports.sh**: Changes the permissions of the `prepare_realm_exports.sh` script to
      make it executable.
    - **/tmp/prepare_realm_exports.sh**: Runs the `prepare_realm_exports.sh` script, which is likely responsible for
      preparing the realm configuration files that Keycloak will use.

###### Purpose of the `realm-setup` Service:

- The `realm-setup` service is used to prepare the configuration for Keycloak realms. It runs a shell script (
  `prepare_realm_exports.sh`) that processes the realm configuration json files in realms folder (e.g.,
  `realm-export.json`) and places them in a location where Keycloak can import them.
- The service uses `alpine` because it's a minimal, efficient image that has the tools needed to process the
  configuration files, like `jq`.
- Once the setup completes, the prepared realm configurations are stored in the `keycloak_data` volume, which is shared
  with the Keycloak container for import during startup.

For more information on the alpine Docker image, check the [official documentation](https://hub.docker.com/_/alpine).

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

#### 2. `keycloak` Service

- **Purpose**: The main Keycloak container for authentication and user management.
- **Image**: quay.io/keycloak/keycloak:26.0
- **Ports**: Exposes Keycloak on port 8080 and management on port 9000.
- **Health Check**: Checks Keycloak's health at the `/health/ready` endpoint.
- **Command**: Starts Keycloak in dev mode and imports realms.

```yaml
keycloak:
  image: quay.io/keycloak/keycloak:26.0
  container_name: keycloak
  env_file:
    - ./.env
  ports:
    - "${KEYCLOAK_PORT}:8080"
    - "${KEYCLOAK_MANAGEMENT_PORT}:9000"
  depends_on:
    realm-setup:
      condition: service_completed_successfully
    postgres:
      condition: service_healthy
  volumes:
    - keycloak_data:/opt/keycloak/data/import
  networks:
    - keycloak_network
  command: [ "start-dev", "--import-realm" ]
  healthcheck:
    test: >
      sh -c "
        exec 3<>/dev/tcp/127.0.0.1/9000 && echo -n 'GET /health/ready HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n' >&3 && \
        cat <&3 && \
        echo 'HTTP/1.1 200 OK' && exit 0 || exit 1
      "
    interval: ${KEYCLOAK_HEALTHCHECK_INTERVAL}
    retries: ${KEYCLOAK_HEALTHCHECK_RETRIES}
    timeout: ${KEYCLOAK_HEALTHCHECK_TIMEOUT}
    start_period: 10s
```

##### Keycloak Service Configuration Explanation

1. **`image: quay.io/keycloak/keycloak:26.0`**  
   Specifies the Docker image to be used for the Keycloak container. In this case, it's version 26.0 of Keycloak from
   `quay.io`. This is the official image for Keycloak.

2. **`container_name: keycloak`**  
   Sets the name of the container to `keycloak`, which helps when managing the container (e.g., stopping or viewing
   logs).

3. **`env_file:`**  
   Loads environment variables from the `.env` file. These variables are used to configure the container, such as ports,
   database credentials, and other service-specific settings.

4. **`ports:`**
    - `${KEYCLOAK_PORT}:8080`: Maps the host machine's `KEYCLOAK_PORT` to port `8080` inside the container. This allows
      access to Keycloak's main interface.
    - `${KEYCLOAK_MANAGEMENT_PORT}:9000`: Maps the host machine's `KEYCLOAK_MANAGEMENT_PORT` to port `9000` inside the
      container, which is used for management interfaces or the Admin Console.

5. **`depends_on:`**  
   Specifies dependencies for the Keycloak container:
    - `realm-setup`: The `realm-setup` service must complete successfully before Keycloak starts.
    - `postgres`: Keycloak waits until the `postgres` service is healthy before starting. This ensures that the database
      is ready.

6. **`volumes:`**
    - `keycloak_data:/opt/keycloak/data/import`: This mounts the `keycloak_data` Docker volume to
      `/opt/keycloak/data/import` inside the container. It's used to import realm configuration files prepared by the
      `realm-setup` service.

7. **`networks:`**
    - `keycloak_network`: Attaches the container to the `keycloak_network` network, allowing it to communicate with
      other containers, like the PostgreSQL database and `realm-setup`.

8. **`command:`**
    - `["start-dev", "--import-realm"]`: This specifies the command to run when the Keycloak container starts. In this
      case, it runs Keycloak in development mode (`start-dev`) and automatically imports realms using the
      `--import-realm` flag.

9. **`healthcheck:`**  
   Defines a health check for the container to ensure that Keycloak is ready to accept requests.
    - **`test:`** This runs a shell script to check the health of the service. It tries to open a TCP connection to port
      `9000` and send an HTTP GET request to `/health/ready`. If the request is successful (i.e., it returns `200 OK`),
      the container is considered healthy.
        - If the connection fails or the health check does not return `200 OK`, the container is considered unhealthy.
    - **`interval:`** Defines the time between health checks (configured using the `KEYCLOAK_HEALTHCHECK_INTERVAL`
      variable from the `.env` file).
    - **`retries:`** The number of retries before marking the container as unhealthy (configured using
      `KEYCLOAK_HEALTHCHECK_RETRIES`).
    - **`timeout:`** The maximum amount of time allowed for the health check to complete (configured using
      `KEYCLOAK_HEALTHCHECK_TIMEOUT`).
    - **`start_period:`** The initial delay before starting the health checks (set to `10s` in this case).

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

#### 3. `keycloak_setup` Service

The keycloak_setup service is used to configure the necessary realm configurations.
It runs an entrypoint script, entrypoint.sh, for realm setup and is triggered after the Keycloak container starts.

```yaml
keycloak_setup:
  container_name: keycloak_setup
  image: appropriate/curl:latest
  env_file:
    - ./.env
    - ../mailhog/.env
  depends_on:
    keycloak:
      condition: service_healthy
  entrypoint:
    - "/bin/sh"
    - "-c"
    - |
      # Install jq for JSON processing
      apk add --no-cache jq

      # Make the configuration script executable
      chmod +x /tmp/configure-keycloak.sh

      # Run the configuration script
      /tmp/configure-keycloak.sh
  volumes:
    - ./configure-keycloak.sh:/tmp/configure-keycloak.sh
  restart: "no"
  tty: false
  networks:
    - keycloak_network
```

##### Explanation:

###### `container_name: keycloak_setup`

Specifies the name of the container as `keycloak_setup`. This helps identify the container for management tasks like
stopping or starting the container.

###### `image: appropriate/curl:latest`

Uses the `appropriate/curl:latest` image, which is a Docker image with `curl` installed. The image is based on Alpine
Linux, providing a lightweight environment to run commands like `curl`. This image is chosen because it is simple and
includes `curl`, which is often useful for interacting with APIs or services over HTTP.

###### `env_file:`

- `.env` and `../mailhog/.env` are environment variable files loaded into the container. These files contain environment
  variables, such as configurations for Keycloak and MailHog, that will be available inside the container.
- The variables are injected into the container during startup, and they can be used in the container's environment or
  scripts.

###### `depends_on:`

- `keycloak`: This specifies that the `keycloak_setup` service depends on the `keycloak` service. The container will
  wait for the `keycloak` service to be healthy before starting. The `condition: service_healthy` ensures that
  `keycloak_setup` will not start until the Keycloak service is up and functioning correctly.

###### `entrypoint:`

The entry point is a shell command (`/bin/sh -c`) that runs a script upon container startup.  
Inside the shell, the following actions occur:

- **Install `jq`:** The command `apk add --no-cache jq` installs the `jq` tool, which is a lightweight and flexible
  command-line JSON processor.
- **Make the configuration script executable:** The script `/tmp/configure-keycloak.sh` is given executable permissions
  with `chmod +x /tmp/configure-keycloak.sh`.
- **Run the configuration script:** The script `/tmp/configure-keycloak.sh` is executed to perform configuration tasks
  for Keycloak (e.g., setting up realms, clients, or other settings).

###### `volumes:`

- `./configure-keycloak.sh:/tmp/configure-keycloak.sh`: This volume mounts the local `configure-keycloak.sh` script to
  the container at `/tmp/configure-keycloak.sh`. This allows the container to access and execute the script.

###### `restart: "no"`

This disables automatic restarts of the container. If the container stops or fails, it will not automatically restart.

###### `tty: false`

This option disables the allocation of a terminal for the container. It is set to `false` because this container doesn't
require an interactive terminal.

###### `networks:`

- `keycloak_network`: This specifies that the container is connected to the `keycloak_network` network, enabling
  communication with other containers in the same network, such as the Keycloak service.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Starting the Services

To start the full infrastructure setup, run:

```bash
./start.sh
```

OR

```bash
docker-compose up -d
```

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Keycloak Realm Setup

For more details, see [README](realms/README.md)

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Conclusion

This setup should provide a robust Keycloak integration with PostgreSQL, LDAP, and MailHog for SMTP email testing. Feel
free to adjust the .env file settings and Docker Compose configuration based on your project requirements.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---