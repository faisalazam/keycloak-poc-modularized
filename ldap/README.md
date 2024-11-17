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

The `.env` file contains the following important configuration variables:

### OpenLDAP Variables

- **LDAP_PORT**: The port for LDAP access (default: `389`).
- **LDAP_HOST_NAME**: The hostname for the OpenLDAP service (default: `openldap`).
- **LDAP_DOMAIN**: The domain for your LDAP setup (default: `example.com`).
- **LDAP_ORGANISATION**: The organization name for your LDAP (default: `example_org`).
- **LDAP_BASE_DN**: The base DN for the LDAP directory (default: `dc=example,dc=com`).
- **LDAP_ADMIN_PASSWORD**: The administrator password for OpenLDAP.
- **LDAP_CONFIG_PASSWORD**: The password for configuring OpenLDAP.
- **LDAP_TLS**: Whether to enable TLS (default: `true`).
- **LDAP_REPLICATION**: Whether replication is enabled (default: `false`).

### phpLDAPadmin Variables

- **PHP_LDAPADMIN_PORT**: The port for accessing phpLDAPadmin (default: `6443`).
- **PHPLDAPADMIN_HTTPS**: Whether to use HTTPS for phpLDAPadmin (default: `false`).
- **PHP_ADMIN_HOST_NAME**: The hostname for the phpLDAPadmin service (default: `phpldapadmin`).
- **PHPLDAPADMIN_LDAP_HOSTS**: The host(s) for the OpenLDAP service (defaults to `${LDAP_HOST_NAME}`).

For more information on environment variables, refer to the
official [osixia/openldap documentation](https://github.com/osixia/docker-openldap)
and [phpLDAPadmin Docker documentation](https://hub.docker.com/r/osixia/phpldapadmin/).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---

## Docker Setup

This folder contains two key files for the Docker setup: `Dockerfile` and `docker-compose.yml`.

### Dockerfile

The `Dockerfile` builds a custom image for OpenLDAP by adding the `sample.ldif` file to the container. This file
contains example data that will be imported into the LDAP server when the container is started.

```dockerfile
FROM osixia/openldap:stable

# Add the LDIF file to the container's assets directory
ADD sample.ldif /container/service/slapd/assets/config/bootstrap/ldif/sample.ldif

# You do not need to run /container/tool/run manually;
# the container will take care of it automatically
```

#### Detailed Explanation:

- **FROM osixia/openldap**: This line pulls the base `osixia/openldap` image, which contains a stable version of
  OpenLDAP.
- **ADD sample.ldif**: This command adds the `sample.ldif` file from the local directory to the container’s specific
  assets directory. This LDIF file contains example LDAP entries (e.g., users, groups) that will be automatically
  imported into the LDAP database during container startup.

The container will automatically run the necessary startup commands: The OpenLDAP container will automatically apply the
`sample.ldif` file to its LDAP database, ensuring it is populated with example data when the service is initialized.

#### To rebuild the image:

If you need to rebuild the image, run the following command:

```bash
docker build -t custom-openldap -f Dockerfile .
```

This will build the Docker image using the specified Dockerfile and tag it as custom-openldap.

### docker-compose.yml

The `docker-compose.yml` file defines two services: `openldap` and `phpadmin`.

- **openldap**: This service runs OpenLDAP using the `osixia/openldap` image. It is configured with the environment
  variables provided in the `.env` file, exposes ports for both LDAP and LDAPS, and includes a health check to verify
  the service is functioning.
- **phpadmin**: This service runs phpLDAPadmin using the `osixia/phpldapadmin` image. It depends on the OpenLDAP service
  and is configured with the same environment variables, allowing you to manage the LDAP service through a web
  interface.

#### docker-compose.yml

```yaml
services:
  openldap:
    build:
      context: .
      dockerfile: Dockerfile
    image: custom-openldap:latest
    container_name: ${LDAP_HOST_NAME}
    env_file:
      - ./.env
    ports:
      - "${LDAP_PORT:-389}:389"
      - "${LDAPS_PORT:-636}:636"
    command: --copy-service
    volumes:
      - ldap_data:/var/lib/ldap
      - ldap_config:/etc/ldap/slapd.d
    healthcheck:
      test: [
        "CMD",
        "ldapsearch",
        "-x",
        "-b", "${LDAP_BASE_DN}",
        "-D", "cn=admin,${LDAP_BASE_DN}",
        "-w", "${LDAP_ADMIN_PASSWORD}"
      ]
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

- **build context:**
    - `context: .` tells Docker Compose to use the current directory as the context for the build process.
    - `dockerfile: Dockerfile` specifies that the `Dockerfile` in the current directory should be used to build the
      image.

- **image:**
    - The image tag specifies the name and optionally the tag for the image that will be created (e.g.,
      `custom-openldap:latest`).
    - This tag ensures that the built image will be named `custom-openldap` with the `latest` tag.
    - The `latest` tag ensures you always get the most recent build of this image when running the container.

- **volumes:**
    - Volumes are used to persist the OpenLDAP data and configuration across container restarts.
    - The volume `ldap_data` stores the LDAP database, and `ldap_config` stores the LDAP configuration.

- **healthcheck:**
    - This configuration ensures that Docker continuously monitors the health of the container. It runs an `ldapsearch`
      command to check if the LDAP service is running correctly.

##### Rebuilding the OpenLDAP image:

To rebuild the image (if necessary), run:

```bash
docker build -t custom-openldap -f Dockerfile .
```

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
docker-compose up
```

This will build the Docker image for OpenLDAP (if not already built), start the services, and expose them on the
specified ports.

To run the services in detached mode, use:

```bash
docker-compose up -d
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
docker-compose logs openldap
docker-compose logs phpadmin
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
  appropriate path (e.g., `/container/service/slapd/assets/config/bootstrap/ldif/`). This ensures that the data is
  automatically imported when the container starts.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

---
