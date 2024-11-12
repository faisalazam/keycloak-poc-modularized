# Docker Secrets Management Setup with Modularized Docker Compose

This project provides a secure, modular Docker Compose setup for managing secrets using shell scripts. Each service has
its own Docker Compose file, `.env` file, and setup scripts, allowing isolated configuration and control. A main Docker
Compose file in the root directory orchestrates all services, and secrets are managed securely with automated scripts.

## Directory Structure

```plaintext
project-root/
│
├── docker-compose.yml            # Main Docker Compose file to run all services
├── .env                           # Root .env file for global environment variables
├── secret_helper.sh               # Helper script for creating and cleaning up secrets
├── start.sh                       # Master script to set up secrets and run all services
│
├── postgres/
│   ├── docker-compose.yml         # Docker Compose file for PostgreSQL and pgAdmin services
│   ├── .env                       # PostgreSQL-specific environment variables
│   ├── create_secrets.sh          # Script to manage secrets for PostgreSQL
│   ├── start.sh                   # Script to set up secrets and run PostgreSQL independently
│   └── README.md                  # Documentation for PostgreSQL setup
│
├── ldap/
│   ├── docker-compose.yml         # Docker Compose file for OpenLDAP and phpLDAPadmin services
│   ├── .env                       # LDAP-specific environment variables
│   ├── create_secrets.sh          # Script to manage secrets for LDAP
│   ├── start.sh                   # Script to set up secrets and run LDAP independently
│   └── README.md                  # Documentation for LDAP setup
│
├── mailhog/
│   ├── docker-compose.yml         # Docker Compose file for MailHog service
│   ├── .env                       # MailHog-specific environment variables
│   ├── create_secrets.sh          # Script to manage secrets for MailHog (if needed)
│   ├── start.sh                   # Script to set up secrets and run MailHog independently
│   └── README.md                  # Documentation for MailHog setup
│
├── keycloak/
│   ├── docker-compose.yml         # Docker Compose file for Keycloak service
│   ├── .env                       # Keycloak-specific environment variables
│   ├── create_secrets.sh          # Script to manage secrets for Keycloak
│   ├── start.sh                   # Script to set up secrets and run Keycloak independently
│   └── README.md                  # Documentation for Keycloak setup
│
└── ...
```

## Step-by-Step Setup

### 1. Environment Variables

Each folder contains a `.env` file with environment variables specific to that service. These files help to keep each
service's configuration organized and isolated. You can define sensitive variables here, like usernames, database names,
and hostnames for the service:

**Example of `postgres/.env`:**

```plaintext
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
PGADMIN_HOST_NAME=pgadmin
```

Note: Sensitive secrets should be handled with caution. Environment variables alone are often insufficient for
production security, which is why we use secrets and secure file handling for passwords.

## 2. Secrets Management

Each service folder contains a `create_secrets.sh` script for secure secret handling. This script generates temporary
secret files without file extensions and cleans them up on exit, ensuring passwords aren’t left on the disk after
service startup.

### Significance of `chmod 600`

The `chmod 600` command is used on each secret file to set permissions, allowing only the file owner to read and write.
This restricts access to the secret, enhancing security by ensuring other users or processes cannot access it.

Example in create_secrets.sh:

```sh
echo "$secret_value" > "$secret_file_path"
chmod 600 "$secret_file_path"  # Restricts access to the file
```

Example of a create_secrets.sh Script  
In each service folder (e.g., postgres/), create_secrets.sh is responsible for generating and exporting the service’s
secrets:

```sh
#!/bin/sh

# Source the common secret helper functions
. ../secret_helper.sh

# Define service-specific secret variables
POSTGRES_PASSWORD="password"
PGADMIN_DEFAULT_PASSWORD="admin"

# Create the secret file
create_secret "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD" "postgres_password"
create_secret "PGADMIN_DEFAULT_PASSWORD" "$PGADMIN_DEFAULT_PASSWORD" "pgadmin_default_password"

# Cleanup on exit
trap 'cleanup_secret "$SECRET_FILE" EXIT'
```

3. Helper Script for Secrets (secret_helper.sh)  
   This helper script provides reusable functions for creating and cleaning up secrets, which can be sourced by
   individual create_secrets.sh scripts.

```sh
#!/bin/sh

# Creates a secret file and exports the _FILE environment variable
create_secret() {
  secret_name=$1
  secret_value=$2
  secret_file_path=$3

  if [ -z "$secret_name" ] || [ -z "$secret_value" ] || [ -z "$secret_file_path" ]; then
    echo "Error: create_secret requires 3 arguments."
    return 1
  fi

  echo "$secret_value" > "$secret_file_path" || return 1
  chmod 600 "$secret_file_path" || return 1
  export "${secret_name}_FILE"="$secret_file_path"
}

# Cleans up the secret file
cleanup_secret() {
  secret_file_path=$1
  if [ -f "$secret_file_path" ]; then
    rm -f "$secret_file_path" || return 1
    echo "Secret file $secret_file_path cleaned up."
  else
    echo "Secret file $secret_file_path not found; skipping cleanup."
  fi
}

# Runs secret setup for a service folder
run_service_setup() {
  service_folder=$1
  if [ -f "$service_folder/create_secrets.sh" ]; then
    ( cd "$service_folder" && ./create_secrets.sh )
  else
    echo "No create_secrets.sh found in $service_folder; skipping."
  fi
}
```

### Script Explanation

This script consists of three functions: create_secret, cleanup_secret, and run_service_setup. Each function plays a
role in managing secrets securely for Docker services.

#### 3.1. `create_secret` Function

The `create_secret` function creates a secret file, sets the appropriate file permissions, and exports an environment
variable pointing to that secret file.

#### Purpose:

- Creates a secret file with the given content (secret value).
- Secures the file by restricting access using `chmod 600`.
- Exports an environment variable pointing to the secret file (`<SECRET_NAME>_FILE`).

#### Steps:

a. **Arguments**: It takes three arguments:

1. `secret_name`: The name for the secret (used for the environment variable).
2. `secret_value`: The actual secret data (password, token, etc.).
3. `secret_file_path`: The path where the secret file will be created.

b. **Checks**: If any argument is missing, it outputs an error and returns `1` (failure).

c. **Create File**: It writes the secret value into the specified file path.

d. **Set Permissions**: It sets the file permissions (`chmod 600`) to ensure only the file owner can read and write to
the file.

e. **Export Environment Variable**: It exports an environment variable (e.g., `SECRET_NAME_FILE`) pointing to the secret
file's location.

#### Error Handling:

- If any step fails (file creation, permission setting), it will return `1` to indicate failure.

---

#### 3.2. `cleanup_secret` Function

The `cleanup_secret` function removes the secret file once it is no longer needed, ensuring sensitive data is not left
behind.

#### Purpose:

- Deletes a secret file after use to prevent sensitive data from lingering in the system.

#### Steps:

a. **Argument**: Takes the `secret_file_path` as an argument.

b. **Checks**: It checks whether the file exists. If the file exists, it deletes the file and prints a cleanup message.
If the file does not exist, it skips the cleanup and prints a warning message.

#### Error Handling:

- If deletion fails, it will return `1` to indicate an error.

---

#### 3.3. `run_service_setup` Function

The `run_service_setup` function runs the `create_secrets.sh` script inside a specific service folder to set up its
secrets.

#### Purpose:

- Runs the `create_secrets.sh` script inside a given service folder (e.g., `postgres`, `keycloak`, etc.).

#### Steps:

a. **Argument**: Takes the `service_folder` as an argument, which is the path to the service directory.

b. **Checks**: It checks if the `create_secrets.sh` script exists in the specified folder. If the script exists, it
navigates to the service folder and runs it.

c. **Skipping**: If the script does not exist in the folder, it prints a message and skips the setup.

---

### Overall Workflow

a. **Secret Creation**: The `create_secret` function is used to securely create secret files for each service and make
the secret available via environment variables.

b. **Service Setup**: The `run_service_setup` function is used to call `create_secrets.sh` within a service folder to
create the necessary secrets for that service.

c. **Cleaning Up**: After use, the `cleanup_secret` function ensures the removal of the secret files to prevent leaving
sensitive data exposed.

---

### Example Use Case

a. **Running the Setup for a Service**:

- You would call `run_service_setup` with the folder of a service (e.g., `postgres`, `keycloak`). This would invoke the
  `create_secrets.sh` script to generate and secure the required secrets for the service.

b. **Managing Secrets**:

- For each service, the `create_secret` function will be invoked to securely create secret files and set appropriate
  permissions. These files can then be used by Docker services to securely handle sensitive data, such as passwords or
  API keys.

c. **Cleaning Up**:

- After the services are up and running, the `cleanup_secret` function can be used to remove secret files once they are
  no longer needed.


4. Master Script (start.sh)  
   This script automates secret creation for each service and runs the main Docker Compose file. It sources
   secret_helper.sh and uses a loop to iterate through each service folder.

```sh
#!/bin/sh

# Source the helper script
. ./secret_helper.sh

# List of service folders (space-separated)
service_folders="postgres ldap mailhog keycloak"

# Set up secrets for each service
echo "Setting up secrets for services..."
for service_folder in $service_folders; do
  r[secret_helper.sh](secret_helper.sh)un_service_setup "./$service_folder" || exit 1
done

# Start all services
docker-compose -f ./docker-compose.yml up -d
```

### Start Scripts for Each Service

Each service folder includes its own start.sh script for individual service setup. This allows for running each service
independently if needed.

#### Example of start.sh in postgres/:

```sh
#!/bin/sh

# Source the common secret helper functions
. ../secret_helper.sh

run_service_setup "./postgres" || exit 1
docker-compose up -d
```

### Running Individual Services

To run a specific service independently, navigate to the service folder and execute:

```sh
cd <service_folder>
./start.sh
```

NOTE: If you're running it from Windows OS, then use Git Bash or something similar which supports POSIX-compliant
shells, so that you can run the script directly.

### 5. How Secrets Are Mapped to Environment Variables

In Docker, secrets and environment variables using secrets are flexible and can be named according to your preference.
The key concept is that some Docker images support using an environment variable with a `_FILE` suffix, which points to
a file containing the actual secret value. For example, setting `POSTGRES_PASSWORD_FILE` to
`/run/secrets/postgres_password` allows the Docker image to read the password securely from that file instead of
plaintext.

This setup is not limited to specific names or paths; you can choose any filename or environment variable names, as long
as you link them consistently in Docker Compose.

#### Example in docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:17.0
    env_file:
      - ../.env
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    ...
secrets:
  postgres_password:
    file: ./postgres_password
```

To understand more about how secrets and environment variables work with Docker, refer
to [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/)
and [Docker environment variables documentation](https://docs.docker.com/compose/environment-variables/).

This approach is widely supported across official images (e.g., Postgres) and is recommended for secure secret
management in production setups.

### 6. Alternatives for Production-Level Secrets Management

For production environments, consider using a dedicated secrets manager like:

- **HashiCorp Vault**: An enterprise-grade solution with fine-grained access control, secret rotation, and extensive
  integrations. [Vault documentation](https://www.vaultproject.io/docs).
- **AWS Secrets Manager**: Manages, rotates, and retrieves secrets for AWS applications and
  services. [AWS Secrets Manager documentation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).
- **Docker Swarm Secrets**: If using Docker Swarm, secrets can be directly managed and stored securely within the Swarm
  infrastructure. [Swarm Secrets documentation](https://docs.docker.com/engine/swarm/secrets/).

### Key Points and Benefits

- Secure, modular setup with isolated configurations for each service.
- Enhanced security with `chmod 600` for secret files.
- Customizable environment variables and secrets, with flexibility to adapt.
