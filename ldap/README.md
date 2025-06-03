# LDAP Setup for Keycloak

This directory contains the setup for OpenLDAP and phpLDAPadmin services, which are part of the modular Keycloak
environment. The configuration allows you to run OpenLDAP with an optional secure TLS setup and manage it using
phpLDAPadmin.

## Table of Contents

- [Overview](#overview)
- [Environment Variables](#environment-variables)
- [Docker Setup](#docker-setup)
    - [Dockerfile](#dockerfile)
    - [docker-compose.yml](#docker-composeyml)
- [Health Check Configuration](#health-check-configuration)
- [Running the Services](#running-the-services)
- [Accessing phpLDAPadmin](#accessing-phpldapadmin)
- [Troubleshooting](#troubleshooting)
- [Sample LDIF File Overview](#sample-ldif-file-overview)

---

## Overview

This setup consists of two main services:

1. **OpenLDAP**: The LDAP server where you can store and manage user data.
2. **phpLDAPadmin**: A web-based LDAP administration tool to interact with the OpenLDAP service.

These services are configured to work together to manage user authentication for Keycloak.

Official documentation links:

- [OpenLDAP Documentation](https://www.openldap.org/doc/)
- [phpLDAPadmin Documentation](https://github.com/LeoFritz/docker-phpLDAPadmin)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Environment Variables

The `.env` file contains important configuration variables for OpenLDAP and phpLDAPadmin services.

### 🔐 OpenLDAP Variables

- **LDAP_PORT**: Port for plain LDAP (default: `1389`).
- **LDAPS_PORT**: Port for secure LDAPS (default: `1636`).
- **LDAP_HOST_NAME**: Hostname of the OpenLDAP container (default: `openldap`).
- **LDAP_DOMAIN**: Domain for LDAP setup (e.g. `example.com`).
- **LDAP_ROOT / LDAP_BASE_DN**: Base DN for LDAP (e.g. `dc=example,dc=com`).
- **LDAP_ORGANIZATION**: Organization name (e.g. `example_org`).
- **LDAP_ADMIN_USERNAME**: LDAP admin username (default: `admin`).
- **LDAP_ADMIN_PASSWORD**: Password for the admin user.
- **SETUP_LDAP**: Toggle for enabling LDAP integration (default: `false`).
- **LDAP_BIND_DN**: Bind DN used by clients to authenticate (e.g. `cn=admin,dc=example,dc=com`).
- **LDAP_BIND_CREDENTIAL**: Password for the bind DN (same as `LDAP_ADMIN_PASSWORD`).
- **LDAP_USERS_DN**: DN under which users are located (e.g. `ou=users,dc=example,dc=com`).

#### TLS Settings

- **LDAP_ENABLE_TLS**: Enable TLS (yes/no).
- **LDAP_REQUIRE_TLS**: Enforce TLS-only connections (yes/no).
- **LDAPTLS_REQCERT**: Client certificate verification policy (`demand`, `allow`, etc.).
- **LDAP_TLS_KEY_FILE**: Path to the TLS private key file.
- **LDAP_TLS_CERT_FILE**: Path to the TLS certificate file.
- **LDAP_TLS_CA_FILE**: Path to the CA bundle used for TLS trust.

#### Health Check

- **LDAP_HEALTHCHECK_INTERVAL**: Interval between health checks (e.g. `30s`).
- **LDAP_HEALTHCHECK_TIMEOUT**: Timeout for health checks (e.g. `10s`).
- **LDAP_HEALTHCHECK_RETRIES**: Number of retries before marking unhealthy.

#### URLs

- **LDAP_URL**: Plain LDAP URL for client access (e.g. `ldap://openldap:1389`).
- **LDAPS_URL**: Secure LDAPS URL (e.g. `ldaps://openldap:1636`).

---

### 🧭 phpLDAPadmin Variables

- **PHP_LDAPADMIN_PORT**: Port for accessing phpLDAPadmin (default: `6443`).
- **PHPLDAPADMIN_HTTPS**: Enable HTTPS for phpLDAPadmin (default: `false`).
- **PHP_ADMIN_HOST_NAME**: Hostname for the phpLDAPadmin service (default: `phpldapadmin`).
- **PHPLDAPADMIN_LDAP_HOSTS**: LDAP server(s) phpLDAPadmin should connect to. It is set from the
  `phpadmin_entrypoint.sh` script based on the `LDAP_ENABLE_TLS` flag.

#### TLS (Client)

- **PHPLDAPADMIN_LDAP_CLIENT_TLS_REQCERT**: TLS cert validation policy (e.g. `demand`).
- **PHPLDAPADMIN_LDAP_CLIENT_TLS_CA_CRT_FILENAME**: Filename for trusted CA certificate (e.g. `ldap_ca.crt`).

---

### 🧪 Quick LDAP Search Examples

```sh
# Plain LDAP
ldapsearch -H ldap://127.0.0.1:1389 \
  -x -b "dc=example,dc=com" \
  -D "cn=admin,dc=example,dc=com" \
  -w ldap_admin_password

# Secure LDAPS
ldapsearch -H ldaps://127.0.0.1:1636 \
  -x -b "dc=example,dc=com" \
  -D "cn=admin,dc=example,dc=com" \
  -w ldap_admin_password

# Secure LDAPS
ldapsearch -H ldaps://openldap:1636 \
  -x -b "dc=example,dc=com" \
  -D "cn=admin,dc=example,dc=com" \
  -w ldap_admin_password
```

For more information on environment variables, refer to the
official [bitnami/openldap documentation](https://github.com/bitnami/containers/tree/main/bitnami/openldap)
and [phpLDAPadmin Docker documentation](https://hub.docker.com/r/osixia/phpldapadmin/).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Docker Setup

This folder contains the key file for the Docker setup: `docker-compose.yml`.

### docker-compose.yml

The `docker-compose.yml` file defines two services: `openldap` and `phpadmin`.

- **openldap**: This service runs OpenLDAP using the `bitnami/openldap` image. It is configured with the environment
  variables provided in the `.env` file, exposes ports for both LDAP and LDAPS, and includes a health check to verify
  the service is functioning.
- **phpadmin**: This service runs phpLDAPadmin using the `osixia/phpldapadmin` image. It depends on the OpenLDAP service
  and is configured with the same environment variables, allowing you to manage the LDAP service through a web
  interface.

#### docker-compose.yml

```yaml
services:
  openldap:
    image: bitnami/openldap:2.6.10
    container_name: ${LDAP_HOST_NAME}
    env_file:
      - ./.env
    ports:
      - "${LDAP_PORT:-1389}:1389"
      - "${LDAPS_PORT:-1636}:1636"
    volumes:
      - ldap_data:/bitnami/openldap
      - ./sample.ldif:/ldifs/sample.ldif # This is where the custom ldifs are loaded from
      - ./scripts/healthcheck.sh:/usr/local/bin/healthcheck.sh:ro
      - ../certs/end_entity/openldap/certificate.pem:/opt/bitnami/openldap/certs/certificate.pem
      - ../certs/end_entity/openldap/private_key.pem:/opt/bitnami/openldap/certs/private_key.pem
      - ../certs/end_entity/openldap/intermediate_and_leaf_chain.bundle:/opt/bitnami/openldap/certs/intermediate_and_leaf_chain.bundle
      - ../certs/certificate_authority/certificate_chains/root_and_intermediate_chain.bundle:/usr/local/share/ca-certificates/ca.crt
    post_start:
      - command: |
          sh -c "
            chown 1001:0 /usr/local/share/ca-certificates/ca.crt && \
            chmod 644 /usr/local/share/ca-certificates/ca.crt && \

            chown 1001:0 /opt/bitnami/openldap/certs/certificate.pem && \
            chown 1001:0 /opt/bitnami/openldap/certs/private_key.pem && \
            chown 1001:0 /opt/bitnami/openldap/certs/intermediate_and_leaf_chain.bundle && \

            chmod 644 /opt/bitnami/openldap/certs/certificate.pem && \
            chmod 600 /opt/bitnami/openldap/certs/private_key.pem && \
            chmod 644 /opt/bitnami/openldap/certs/intermediate_and_leaf_chain.bundle && \

            update-ca-certificates
          "
        user: root
    healthcheck:
      test: [ "CMD-SHELL", "sh /usr/local/bin/healthcheck.sh" ]
      interval: ${HEALTHCHECK_INTERVAL:-30s}
      timeout: ${HEALTHCHECK_TIMEOUT:-10s}
      retries: ${HEALTHCHECK_RETRIES:-5}
    networks:
      - keycloak_network

  phpadmin:
    image: osixia/phpldapadmin:latest
    container_name: ${PHP_ADMIN_HOST_NAME}
    env_file:
      - ./.env
    ports:
      - "${PHP_LDAPADMIN_PORT:-6443}:80"
    depends_on:
      openldap:
        condition: service_healthy
    volumes:
      - phpldapadmin_data:/var/www/phpldapadmin
      - ./scripts/phpadmin_entrypoint.sh:/usr/local/bin/entrypoint.sh:ro
      # If the ../certs dir is missing, then run `../scripts/generate_certificate.sh` first to generate the certificates.
      - ../certs/certificate_authority/certificate_chains/root_and_intermediate_chain.bundle:/container/service/ldap-client/assets/certs/${PHPLDAPADMIN_LDAP_CLIENT_TLS_CA_CRT_FILENAME}
    entrypoint: [ "sh", "/usr/local/bin/entrypoint.sh" ]
    healthcheck:
      test: [
        "CMD",
        "php",
        "-r",
        "if (@file_get_contents('http://localhost:80')) exit(0); else exit(1);"
      ]
      interval: ${HEALTHCHECK_INTERVAL:-30s}
      timeout: ${HEALTHCHECK_TIMEOUT:-10s}
      retries: ${HEALTHCHECK_RETRIES:-5}
    networks:
      - keycloak_network
```

##### Detailed Explanation:

- **image:**
    - The image tag specifies the name and optionally the tag for the image that will be used (e.g.,
      `bitnami/openldap:2.6.10`).
    - This tag ensures that the used image will be named `bitnami/openldap` with the `2.6.10` tag.
    - The `2.6.10` tag ensures you always get the stable build of this image when running the container.

- **volumes:**
    - Volumes are used to persist the OpenLDAP data across container restarts.
    - The volume `ldap_data` stores the LDAP related data.

- **healthcheck:**
    - This configuration ensures that Docker continuously monitors the health of the container. It runs an `ldapsearch`
      command to check if the LDAP service is running correctly.

For more information about `docker-compose.yml` configuration, refer to the
official [Docker Compose documentation](https://docs.docker.com/compose/).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Health Check Configuration

Both services (`openldap` and `phpadmin`) have health checks configured to ensure that they are running properly. These
health checks will attempt to query the respective services and ensure they respond correctly.

- **OpenLDAP Health Check**: Performs an LDAP search using the `ldapsearch` command.
- **phpLDAPadmin Health Check**: Performs an HTTP request to check the availability of the phpLDAPadmin interface.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Running the Services

### Option 1: Using docker-compose

To start the OpenLDAP and phpLDAPadmin services, use the following command:

```bash
docker compose up
```

This will build the Docker image for OpenLDAP (if not already built), start the services, and expose them on the
specified ports.

To run the services in detached mode, use:

```bash
docker compose up -d
```

### Option 2: Using start.sh

Alternatively, you can start the services using the provided start.sh script, which will execute the same Docker Compose
commands.

```bash
./start.sh
```

Ensure that the start.sh script has executable permissions. If not, run:

```bash
chmod +x start.sh
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Accessing phpLDAPadmin

Once the services are running, you can access phpLDAPadmin via the following URL:

```
http://localhost:${PHP_LDAPADMIN_PORT:-6443}
```

Use the following credentials to log in:

- **Login DN**: `cn=admin,dc=example,dc=com`
- **Password**: `ldap_admin_password`

For more details about phpLDAPadmin, refer to the [phpLDAPadmin documentation](https://phpldapadmin.github.io/).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Troubleshooting

If you encounter issues, try the following:

- Ensure the services are healthy by checking the logs using:

```bash
docker compose logs openldap
docker compose logs phpadmin
```

- Check that the correct ports are exposed and not blocked by any firewall.

- Verify the health check configurations in the `docker-compose.yml` file to ensure services are starting correctly.

For more troubleshooting tips, refer to the
official [OpenLDAP troubleshooting guide](https://www.openldap.org/doc/admin24/troubleshooting.html)
and [phpLDAPadmin troubleshooting](https://github.com/osixia/docker-phpLDAPadmin/wiki/Troubleshooting).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Sample LDIF File Overview

This `sample.ldif` file contains LDAP data in **LDIF (LDAP Data Interchange Format)**, a standard for representing
directory service entries. It includes users, organizational units (OUs), and groups for an LDAP directory structure.

The file is automatically imported into the LDAP server when the container starts, ensuring the directory is
pre-populated with example data.

Here’s a breakdown of what the file contains and how it works:

1. **LDAP Base DN**:

- The placeholders `{{ LDAP_BASE_DN }}` should be replaced with your actual LDAP base distinguished name (DN) in the
  environment, which is typically the root from which all entries are structured (e.g., `dc=example,dc=com`).
- Example: `dn: cn=admin,dc=example,dc=com`.

2. **Admin User (Directory Administrator)**:

- The `cn=admin` entry is a **directory administrator** who has full access to the LDAP directory.
- It includes attributes like `userPassword` (for authentication), `mail` (admin's email), and `telephoneNumber`.

3. **Organizational Units (OUs)**:

- The `ou=users`, `ou=groups`, and `ou=departments` entries represent different **organizational units** (OUs) in the
  directory.
- OUs are logical groupings used to categorize entities in the directory.

4. **Groups**:

- Groups (`cn=developers`, `cn=qa`, `cn=ops`, and `cn=managers`) are used to organize users with similar roles or
  responsibilities.
- The `member` attribute within each group defines which users belong to the group by referencing the user’s DN.

5. **Users**:

- Each user is represented by a `uid=<username>` entry, with common attributes like `givenName`, `sn` (surname),
  `mail` (email address), `telephoneNumber`, and `title`.
- The `userPassword` attribute is used for authentication, and the `departmentNumber` links users to specific
  departments.

6. **Attributes of Importance**:

- **`objectClass`**: Defines the type of object (e.g., `inetOrgPerson` for users, `groupOfNames` for groups,
  `organizationalUnit` for OUs).
- **`dn` (Distinguished Name)**: Uniquely identifies an entry within the LDAP directory.
- **`uid`**: A unique identifier for each user, typically used for login.
- **`cn`**: Common Name, often used to represent a person's full name or group name.
- **`userPassword`**: The password for authentication.

### Key Points:

- **LDIF Format**: It is a textual representation of LDAP directory entries. Each entry is separated by a blank line and
  includes the DN (Distinguished Name) followed by a series of attributes and their values.
- **Users and Groups**: The file defines both users and groups. Groups can have multiple members (users), and users can
  belong to different groups.
- **Hierarchical Structure**: LDAP data is organized in a tree structure, where DNs (such as
  `cn=admin,{{ LDAP_BASE_DN }}`) represent nodes in the tree.
- **Attributes**: Each LDAP entry can have several attributes, like `mail`, `telephoneNumber`, `userPassword`, which are
  used for authentication and storing user details.

### Usage in Your Setup:

- This `sample.ldif` can be imported into your LDAP server to populate it with sample data.
- If using Docker with OpenLDAP, the `LDIF` file should be placed in a directory that is mounted to the container at the
  appropriate path (e.g., `/ldifs/`). This ensures that the data is automatically imported when the container starts.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---
