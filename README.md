
[![CI](https://github.com/faisalazam/keycloak-poc-modularized/actions/workflows/ci.yml/badge.svg)](https://github.com/faisalazam/keycloak-poc-modularized/actions/workflows/ci.yml)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://faisalazam.github.io/keycloak-poc-modularized/postman-report.html)
![Keycloak](https://img.shields.io/badge/Keycloak-active-blue?style=flat-square)
![PhpLdapAdmin](https://img.shields.io/badge/PhpLdapAdmin-active-blue?style=flat-square)
![LDAP](https://img.shields.io/badge/LDAP-active-blue?style=flat-square)
![PgAdmin](https://img.shields.io/badge/PgAdmin-active-blue?style=flat-square)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-active-blue?style=flat-square)
![Mailhog](https://img.shields.io/badge/Mailhog-active-blue?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-active-blue?style=flat-square)


### CI/CD and Test Results
![CI](https://img.shields.io/badge/CI-passing-brightgreen?style=flat-square)
![Tests](https://img.shields.io/badge/Tests-passing-brightgreen?style=flat-square)

### Service Availability
![Keycloak](https://img.shields.io/badge/Keycloak-active-blue?style=flat-square)
![PgAdmin](https://img.shields.io/badge/PgAdmin-active-blue?style=flat-square)
![LDAP](https://img.shields.io/badge/LDAP-active-blue?style=flat-square)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-active-blue?style=flat-square)
![Mailhog](https://img.shields.io/badge/Mailhog-active-blue?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-active-blue?style=flat-square)

### Additional Information
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
![Docker Image Size](https://img.shields.io/docker/image-size/faisalazam/keycloak-poc-modularized?style=flat-square)
![Stars](https://img.shields.io/github/stars/faisalazam/keycloak-poc-modularized?style=flat-square)

# Docker Keycloak LDAP Setup

This project sets up a modularized Docker environment for Keycloak with LDAP integration, along with additional services
like MailHog and phpLDAPadmin.

## Folder Structure

- `keycloak/`: Contains Keycloak setup and MailHog for SMTP testing.
- `ldap/`: Contains LDAP setup, sample data, and phpLDAPadmin for LDAP management.
- `main-docker-compose.yml`: Main Docker Compose file to orchestrate all services.
- `main.env`: Centralized environment configuration for all services.
- `Keycloak_Postman_Collection.json`: Postman collection to test Keycloak functionalities.

Each folder has its own `README.md` file with service-specific setup and testing details.

### Usage

1. Make sure Docker and Docker Compose are installed.
2. Configure environment variables in `main.env`.
3. Run the main Docker Compose file to start all services:

```bash
docker-compose -f main-docker-compose.yml up -d
```

[Mailhog](mailhog/README.md)
[Postgres](postgres/README.md)