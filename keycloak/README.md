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

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

#### 3. `keycloak_setup` Service

The keycloak_setup service is used to configure the necessary realm configurations.
It runs an entrypoint script, entrypoint.sh, for realm setup and is triggered after the Keycloak container starts.

```yaml
keycloak_setup:
  image: alpine:3.16
  container_name: keycloak-setup
  depends_on:
    - keycloak
  environment:
    - KEYCLOAK_HOST=${KEYCLOAK_HOST}
  entrypoint: /opt/keycloak/entrypoint.sh
  networks:
    - keycloak_network
```

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