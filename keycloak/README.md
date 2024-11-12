# Keycloak Service with LDAP Integration

This folder sets up Keycloak along with MailHog for SMTP functionality.

## Files
- `docker-compose-keycloak.yml`: Keycloak Docker Compose file.
- `.env`: Environment variables for Keycloak.
- `realm-export.json`: Contains sample realm and user data.
- `configure-keycloak.sh`: Script to configure LDAP and MailHog integration.

## Usage
1. Ensure that `main.env` is configured with Keycloak and MailHog settings.
2. Start Keycloak:
   ```bash
   docker-compose -f docker-compose-keycloak.yml up -d
