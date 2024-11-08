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

[Mailhog](mailhog/README.md)
