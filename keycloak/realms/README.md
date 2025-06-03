# Realms in Keycloak

## What is a Realm in Keycloak?

A **realm** in Keycloak is a core concept in Keycloak. It is a logical container that manages a set of users, groups,
roles, and clients. Realms are isolated from each other, which means configurations in one realm do not affect others.
This allows Keycloak to support multi-tenancy, where multiple clients or organizations can share a single Keycloak
server while keeping their configurations and user data separate.

### Why do we need Realms?

- **Multi-tenancy**: Realms provide secure isolation for different organizations or departments within the same Keycloak
  instance.
- **Isolation**: Realms provide complete isolation of user data, roles, and authentication policies for different
  clients or use cases.
- **Customization**: Each realm can have its own configurations, such as login themes, authentication flows, and
  integrations with LDAP or SMTP servers.
- **Flexibility**: Realms allow managing different applications or services independently.
- **Resource Segregation**: Realms ensure that user and client resources remain separate.

[Learn more about Realms in Keycloak](https://www.keycloak.org/docs/latest/server_admin/#realms)

---

## Table of Contents

1. [Structure of the Realms Folder](#structure-of-the-realms-folder)
2. [Environment Variables for Conditional Configurations](#environment-variables-for-conditional-configurations)
3. [Explanation of JSON Files](#explanation-of-json-files)
    1. [1. `realm-export.json`](#1-realm-exportjson)
    2. [2. `users.json`](#2-usersjson)
    3. [3. `smtp.json`](#3-smtpjson)
    4. [4. `ldap.json`](#4-ldapjson)
4. [Importing and Exporting Realms](#importing-and-exporting-realms)
    1. [Using Keycloak GUI](#using-keycloak-gui)
    2. [Using the --import-realm Option](#using-the---import-realm-option)
    3. [Using the Keycloak API](#using-the-keycloak-api)
5. [Links to Official Documentation](#links-to-official-documentation)

---

## Structure of the Realms Folder

Keycloak allows you to create isolated authentication domains called realms. A realm manages a set of users,
credentials, roles, and groups. It also manages client applications, their credentials, and session details.

The `realms` folder in this project organizes realm configurations in separate subfolders, one per realm. Each realm
folder can contain the following JSON files:

1. **`realm-export.json`**: Base configuration of the realm.
2. **`users.json`**: Defines users to be imported into the realm.
3. **`smtp.json`**: Configures the SMTP server for the realm.
4. **`ldap.json`**: Configures LDAP integration for the realm.

---

## Environment Variables for Conditional Configurations

The inclusion of `users.json`, `smtp.json`, and `ldap.json` files is controlled via environment variables:

- `SETUP_LDAP=true` to enable LDAP configuration.
- `SETUP_SMTP=true` to configure the SMTP server.
- `SETUP_USERS=true` to import user data.

There is a shell script which will scan all these folders, merge them, substitute the environment variables with their
values, and then finally create a fully merged realm json file per realm.

---

## Explanation of JSON Files

### 1. `realm-export.json`

```json
{
  "realm": "quantumrealm",
  "enabled": true,
  "resetPasswordAllowed": true,
  "clients": [
    {
      "enabled": true,
      "protocol": "openid-connect",
      "clientId": "quantum-user-mgmt-client",
      "redirectUris": [
        "${QUANTUM_REALM_REDIRECT_URI}"
      ]
    }
  ],
  "users": []
}
```

#### Fields Explanation:

- `realm`: The name of the realm (e.g., "quantumrealm").
- `enabled`: Whether the realm is active.
- `resetPasswordAllowed`: Allows users to reset passwords via email.
- `clients`: A list of clients within the realm, including:
    - `clientId`: The unique identifier for the client.
    - `protocol`: The protocol used (e.g., openid-connect).
    - `redirectUris`: Allowed URIs for redirection post-login/logout.
- `users`: A placeholder for user configurations (optional).

[Go to Table of Contents](#table-of-contents)
[Go back to Keycloak](../README.md)
[Go back to Project](../../README.md)

---

### 2. `users.json`

```json
{
  "users": [
    {
      "username": "kzUser3",
      "enabled": true,
      "firstName": "User",
      "lastName": "Three",
      "email": "kzuser3@example.com",
      "credentials": [
        {
          "type": "password",
          "value": "password3",
          "temporary": false
        }
      ]
    }
  ]
}
```

#### Fields Explanation:

- `username`: Unique identifier for the user.
- `enabled`: Whether the user account is active.
- `credentials`: Stores user authentication details:
    - `type`: Specifies the credential type (e.g., password).
    - `value`: The user's password or token.
    - `temporary`: Marks the password as temporary, forcing the user to change it upon login.

[Go to Table of Contents](#table-of-contents)
[Go back to Keycloak](../README.md)
[Go back to Project](../../README.md)

---

### 3. `smtp.json`

```json
{
  "smtpServer": {
    "auth": "${SMTP_AUTH}",
    "port": "${SMTP_PORT}",
    "host": "${SMTP_HOST}",
    "user": "${SMTP_USER}",
    "from": "${SMTP_FROM}",
    "replyTo": "${SMTP_REPLY_TO}",
    "password": "${SMTP_PASSWORD}",
    "starttls": "${SMTP_STARTTLS}",
    "encryption": "${SMTP_ENCRYPTION}",
    "fromDisplayName": "${SMTP_FROM_DISPLAY_NAME}"
  }
}
```

#### Fields Explanation:

- **auth**: Specifies whether authentication is required (true/false).
- **port**: The SMTP server port.
- **host**: SMTP server hostname.
- **user / password**: SMTP server credentials.
- **from**: The "From" email address.
- **replyTo**: The "Reply-To" email address.
- **starttls / encryption**: Configures secure communication options.
- **fromDisplayName**: Display name for the sender.

[Keycloak Email Configuration Documentation](https://www.keycloak.org/docs/latest/server_admin/#email)

[Go to Table of Contents](#table-of-contents)
[Go back to Keycloak](../README.md)
[Go back to Project](../../README.md)

---

### 4. `ldap.json`

The `ldap.json` file configures the integration between Keycloak and an LDAP server for user management and
synchronization. LDAP serves as an external user store, and this configuration allows Keycloak to connect, map user
attributes, and manage users from LDAP.

---

#### Detailed Configuration

```json
{
  "components": {
    "org.keycloak.storage.UserStorageProvider": [
      {
        "id": "quantum-auth-ldap",
        "name": "QuantumAuthHub",
        "providerId": "ldap",
        "subComponents": {
          "org.keycloak.storage.ldap.mappers.LDAPStorageMapper": [
            {
              "name": "uid-ldap-mapper",
              "providerId": "user-attribute-ldap-mapper",
              "config": {
                "ldap.attribute": ["uid"],
                "user.model.attribute": ["username"],
                "is.mandatory.in.ldap": ["false"],
                "read.only": ["false"]
              }
            },
            ...
          ]
        },
        "config": {
          "enabled": ["true"],
          "priority": ["0"],
          "fullSyncPeriod": ["-1"],
          "changedSyncPeriod": ["-1"],
          "cachePolicy": ["DEFAULT"],
          "bindDn": ["${LDAP_BIND_DN}"],
          "bindCredential": ["${LDAP_BIND_CREDENTIAL}"],
          "connectionUrl": ["${LDAP_CONNECTION_URL}"],
          "usersDn": ["${LDAP_USERS_DN}"],
          "authType": ["simple"],
          "useTruststoreSpi": ["always"],
          "connectionPooling": ["true"],
          "connectionTimeout": ["5000"],
          "startTls": ["false"],
          "editMode": ["WRITABLE"],
          "userObjectClasses": ["inetOrgPerson"],
          "usernameLDAPAttribute": ["uid"],
          "rdnLDAPAttribute": ["uid"],
          "uuidLDAPAttribute": ["entryUUID"],
          "ldapSyncTimeout": ["30000"],
          "pagination": ["true"],
          "userSearchFilter": ["(objectClass=inetOrgPerson)"]
        }
      }
    ]
  }
}
```

##### Fields Explained

###### Main LDAP Settings

The `config` section defines essential parameters for the LDAP connection:

- **enabled**: Specifies whether the LDAP provider is active (true or false).
- **priority**: Determines the order in which providers are queried (lower numbers are higher priority).
- **connectionUrl**: The LDAP server's URL (e.g., ldap://localhost:389 or ldaps://localhost:636).
- **bindDn**: The distinguished name (DN) used for binding to the LDAP server.
- **bindCredential**: Password for the bind DN (stored securely using environment variables).
- **usersDn**: The base DN where user objects are located (e.g., ou=users,dc=example,dc=com).
- **authType**: Specifies the authentication type (e.g., simple).
- **editMode**: Defines how Keycloak manages users in LDAP:
    - **READ_ONLY**: Keycloak cannot modify LDAP user attributes.
    - **WRITABLE**: Keycloak can update LDAP user attributes.
    - **UNSYNCED**: Keycloak users are stored locally and not synced with LDAP.
- **userObjectClasses**: The object class used for LDAP user entries (e.g., inetOrgPerson).
- **usernameLDAPAttribute**: The LDAP attribute mapped to Keycloak's username.
- **pagination**: Enables LDAP pagination for large user bases.
- **userSearchFilter**: An LDAP filter for searching users (e.g., (objectClass=inetOrgPerson)).
- **connectionTimeout**: Timeout for LDAP connections, in milliseconds.
- **startTls**: Enables STARTTLS for secure communication (true or false).
- **useTruststoreSpi**: Specifies truststore behavior for secure connections:
    - **always**: Always use the truststore.
    - **ldapsOnly**: Only use the truststore for LDAPS connections.

###### Attribute Mappers

Attribute mappers (LDAPStorageMapper) link LDAP attributes to Keycloak user properties. Each mapper specifies:

- **name**: A descriptive name for the mapper.
- **providerId**: The mapper type (e.g., user-attribute-ldap-mapper).
- **ldap.attribute**: The LDAP attribute (e.g., uid, mail, telephoneNumber).
- **user.model.attribute**: The Keycloak user property to map to (e.g., username, email).
- **is.mandatory.in.ldap**: Whether the attribute is required in LDAP.
- **read.only**: Specifies if the attribute is read-only.

| Mapper Name            | LDAP Attribute   | Keycloak Property | Mandatory | Read-Only |
|------------------------|------------------|-------------------|-----------|-----------|
| uid-ldap-mapper        | uid              | username          | No        | No        |
| first-name-ldap-mapper | givenName        | firstName         | No        | No        |
| last-name-ldap-mapper  | sn               | lastName          | No        | No        |
| email-ldap-mapper      | mail             | email             | No        | No        |
| phone-ldap-mapper      | telephoneNumber  | phoneNumber       | No        | No        |
| title-ldap-mapper      | title            | title             | No        | No        |
| department-ldap-mapper | departmentNumber | department        | No        | No        |

##### Sync Options

Keycloak supports three modes of LDAP synchronization:

- **Full Sync**: Imports all users from LDAP.
- **Changed Sync**: Synchronizes only users who have changed since the last sync.
- **Manual Sync**: Can be triggered from the Admin Console or through Keycloak's API.

These options can be configured in the `config` section:

| Option            | Description                     | Example Value |
|-------------------|---------------------------------|---------------|
| fullSyncPeriod    | Interval for full sync (in sec) | -1 (disabled) |
| changedSyncPeriod | Interval for changed sync (sec) | -1 (disabled) |
| ldapSyncTimeout   | Timeout for sync operations     | 30000 (ms)    |

[Keycloak LDAP Integration Documentation](https://www.keycloak.org/docs/latest/server_admin/#ldap)

[Go to Table of Contents](#table-of-contents)
[Go back to Keycloak](../README.md)
[Go back to Project](../../README.md)

---

## Importing and Exporting Realms

### Using Keycloak GUI

1. Navigate to the Admin Console.
2. Use the Import/Export option to upload/download realms.

### Using the `--import-realm` Option

1. Add `--import-realm` to Keycloak's startup script.
2. Place the realm JSON files in the configured import directory, i.e. `/opt/keycloak/data/import`.

### Using the Keycloak API

1. Authenticate using admin credentials.
2. Use the `/admin/realms/{realm}` endpoint to import/export realms.

[Go to Table of Contents](#table-of-contents)
[Go back to Keycloak](../README.md)
[Go back to Project](../../README.md)

---

## Links to Official Documentation

- [Realms in Keycloak](https://www.keycloak.org/docs/latest/server_admin/#realms)
- [Keycloak LDAP Integration](https://www.keycloak.org/docs/latest/server_admin/#ldap)
- [Keycloak SMTP Configuration](https://www.keycloak.org/docs/latest/server_admin/#smtp)

[Go to Table of Contents](#table-of-contents)
[Go back to Keycloak](../README.md)
[Go back to Project](../../README.md)
