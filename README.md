[![CI](https://github.com/faisalazam/keycloak-poc-modularized/actions/workflows/ci.yml/badge.svg)](https://github.com/faisalazam/keycloak-poc-modularized/actions/workflows/ci.yml)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://faisalazam.github.io/keycloak-poc-modularized/postman-report.html)

![Keycloak](https://img.shields.io/badge/Keycloak-active-blue?style=flat-square)
![PhpLdapAdmin](https://img.shields.io/badge/PhpLdapAdmin-active-blue?style=flat-square)
![LDAP](https://img.shields.io/badge/LDAP-active-blue?style=flat-square)
![PgAdmin](https://img.shields.io/badge/PgAdmin-active-blue?style=flat-square)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-active-blue?style=flat-square)
![Mailhog](https://img.shields.io/badge/Mailhog-active-blue?style=flat-square)
![Apache](https://img.shields.io/badge/Apache-active-blue?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-active-blue?style=flat-square)

# Keycloak POC Modularized Setup

This repository contains a modularized setup for deploying Keycloak, PostgreSQL, MailHog, LDAP, and phpLDAPadmin using
Docker Compose. The services are separated into individual folders for easy configuration and management. The setup is
designed to provide an isolated environment for each service.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Service Setups](#service-setups)
    - [Keycloak](#keycloak)
    - [PostgreSQL](#postgresql)
    - [MailHog](#mailhog)
    - [OpenLDAP](#ldap)
    - [phpLDAPadmin](#phpldapadmin)
    - [Apache Reverse Proxy](#apache-reverse-proxy)
4. [Instructions](#instructions)
5. [Postman Collection](#postman-collection)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Deployment](#deployment)
8. [Handy Docker Commands](#handy-docker-commands)
9. [Relevant Links and Official Documentation](#relevant-links-and-official-documentation)

---

## Overview

This setup includes:

- **Keycloak** for identity and access management.
- **PostgreSQL** as the database for Keycloak.
- **MailHog** to capture and view SMTP messages for testing.
- **OpenLDAP** for managing user directories.
- **phpLDAPadmin** to manage and view the LDAP directory.
- **Apache Reverse Proxy** to route and secure requests.

The goal is to have these services integrated with minimal configuration to enable Keycloak to work with LDAP and
MailHog for authentication and email testing.

[Go to Table of Contents](#table-of-contents)

---

## Project Structure

```
 keycloak-poc-modularized
 ├── README.md
 ├── docker-compose.yml
 ├── .github
 │   ├── configure-keycloak.sh
 │   ├── docker-compose.yml
 │   ├── prepare_realm_exports.sh
 │   ├── workflows
 │   │   ├── scripts
 │   │   │   ├── check_health.sh
 │   │   │   ├── install_docker.sh
 │   │   │   └── install_npm_dependencies.sh
 │   │   └── ci.yml
 │   └── README.md
 ├── apache-server
 │   ├── conf
 │   │   ├── httpd.conf
 │   │   ├── keycloak-reverse-proxy.conf
 │   │   └── README.md
 │   ├── .env
 │   ├── docker-compose.yml
 │   ├── start.sh
 │   ├── startup_script.sh
 │   └── README.md
 ├── keycloak
 │   ├── configure-keycloak.sh
 │   ├── docker-compose.yml
 │   ├── prepare_realm_exports.sh
 │   ├── realms
 │   │   ├── quantum
 │   │   │   ├── ldap.json
 │   │   │   ├── realm-export.json
 │   │   │   ├── smtp.json
 │   │   │   └── users.json
 │   │   ├── zenith
 │   │   │   ├── ldap.json
 │   │   │   ├── realm-export.json
 │   │   │   ├── smtp.json
 │   │   │   └── users.json
 │   │   └── README.md
 │   ├── start.sh
 │   └── README.md
 ├── ldap
 │   ├── Dockerfile
 │   ├── docker-compose.yml
 │   ├── sample.ldif
 │   ├── start.sh
 │   └── README.md
 ├── mailhog
 │   ├── README.md
 │   ├── docker-compose.yml
 │   └── start.sh
 ├── postgres
 │   ├── Dockerfile.pgadmin
 │   ├── README.md
 │   ├── docker-compose.yml
 │   ├── init_pgadmin.sh
 │   ├── pgpass.template
 │   ├── servers.json.template
 │   └── start.sh
 ├── postman
 │   ├── keycloak-local.postman_environment.json
 │   ├── keycloak-postman-collection.json
 │   └── README.md
 ├── start.sh
 └── startup_helper.sh
```

---

[Go to Table of Contents](#table-of-contents)

## Service Setups

### Keycloak

Keycloak is configured to work with OpenLDAP for authentication and uses PostgreSQL for storing its data. You can find
more details about Keycloak setup in the [Keycloak README](./keycloak/README.md).

With the reverse proxy in place, Keycloak should be accessible on the following URLs:

BASE_URL = http://${APACHE_HOST}:${HTTPD_PORT} => Let's assume APACHE_HOST is localhost and HTTPD_PORT is 80:

So BASE_URL = http://localhost:80 => http://localhost

* http://localhost/robots.txt
* http://localhost/admin
* http://localhost/admin/${REALM_NAME}/console => Case sensitive realm name
    * http://localhost/admin/master/console
    * http://localhost/admin/zenithrealm/console
    * http://localhost/admin/quantumrealm/console
* http://localhost/realms/${REALM_NAME}/account => Case sensitive realm name
    * http://localhost/realms/master/account
    * http://localhost/realms/zenithrealm/account
    * http://localhost/realms/quantumrealm/account
* http://localhost/realms/zenithrealm/protocol/openid-connect/auth?client_id=account
* http://localhost/realms/zenithrealm/protocol/openid-connect/auth?client_id=security-admin-console

If reverse proxy is disabled, then access them from the keycloak host (i.e. localhost) and ${KEYCLOAK_PORT}.

**Keycloak Documentation:** [Keycloak Documentation](https://www.keycloak.org/documentation)

[Go to Table of Contents](#table-of-contents)

### PostgreSQL

PostgreSQL is used as the database for Keycloak. It is configured to persist data and integrate seamlessly with the
Keycloak container. More details can be found in the [PostgreSQL README](./postgres/README.md).

**PostgreSQL Documentation:** [PostgreSQL Documentation](https://www.postgresql.org/docs/)

[Go to Table of Contents](#table-of-contents)

### MailHog

MailHog is used for capturing and viewing emails during the development and testing phases. You can find more details in
the [MailHog README](./mailhog/README.md).

**MailHog Documentation:** [MailHog Documentation](https://github.com/mailhog/MailHog)

[Go to Table of Contents](#table-of-contents)

### LDAP

OpenLDAP is used for managing user directories for Keycloak authentication. For more information on setting up OpenLDAP,
visit the [LDAP README](./ldap/README.md).

[Go to Table of Contents](#table-of-contents)

### phpLDAPadmin

phpLDAPadmin is a web-based client for managing and viewing the LDAP directory. You can find more details in
the [phpLDAPadmin README](./ldap/README.md).

**phpLDAPadmin Documentation:** [phpLDAPadmin Documentation](https://phpldapadmin.sourceforge.io/)

[Go to Table of Contents](#table-of-contents)

### Apache Reverse Proxy

Apache is used as a reverse proxy to route and secure requests to the services, particularly Keycloak. You can find
detailed configuration steps in the [Apache README](./apache-server/README.md).

**Apache Documentation:** [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)

[Go to Table of Contents](#table-of-contents)

---

## Instructions

To clone and run the project, follow these steps:

1. **Clone the repository:**

```bash
git clone https://github.com/faisalazam/keycloak-poc-modularized.git
cd keycloak-poc-modularized
```

2. **Start the services**:

To start all the services in the project, run the following command in the root directory:

```bash
./start.sh
```

This will bring up all the services defined in the `docker-compose.yml` files.

---

[Go to Table of Contents](#table-of-contents)

## Postman Collection

The repository includes a [Postman collection](./postman/keycloak-postman-collection.json) that can be used to test the
Keycloak setup. It can be imported into Postman and run with the associated environment file located
at [keycloak-local.postman_environment.json](./postman/keycloak-local.postman_environment.json).

For more details on Postman setup and usage, visit the [Postman README](./postman/README.md).

[Go to Table of Contents](#table-of-contents)

---

## CI/CD Pipeline

For detailed instructions on the GitHub CI setup used for this project, check out the [README.md](CI_README.md).

[Go to Table of Contents](#table-of-contents)

---

## Deployment

The deployment of this project is done automatically via the GitHub CI pipeline. You can view the deployment at:

[GitHub CI](https://github.com/faisalazam/keycloak-poc-modularized/actions)

[GitHub Pages Deployment](https://faisalazam.github.io/keycloak-poc-modularized)

[Go to Table of Contents](#table-of-contents)

---

## Handy Docker Commands

To view the logs of the running containers, use the following command:

```bash
docker compose logs
```

To stop all the running services, use:

```bash
docker compose down
```

To rebuild the containers and restart the services, use:

```bash
docker compose up --build
```

---

[Back to Table of Contents](#table-of-contents)

## Relevant Links and Official Documentation

- **Keycloak Documentation:** [Keycloak Documentation](https://www.keycloak.org/documentation)
- **PostgreSQL Documentation:** [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- **Docker Documentation:** [Docker Documentation](https://docs.docker.com/)
- **Docker Compose Documentation:** [Docker Compose Documentation](https://docs.docker.com/compose/)
- **MailHog Documentation:** [MailHog Documentation](https://github.com/mailhog/MailHog)
- **phpLDAPadmin Documentation:** [phpLDAPadmin Documentation](https://phpldapadmin.sourceforge.io/)
- **Apache Documentation:** [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)

[Back to Table of Contents](#table-of-contents)

---
