# MailHog Setup with Docker

This guide explains how to set up **MailHog** using Docker, which captures emails sent from applications (like Keycloak)
in a development environment for testing purposes.

## What is MailHog?

**MailHog** is an email testing tool that acts as a dummy SMTP server, allowing you to capture and inspect emails in a
development environment without actually sending them. This setup helps developers verify email functionality without
sending real emails, making it ideal for testing. MailHog’s web interface provides a convenient way to view, search, and
delete emails.

**Why MailHog?** For development, MailHog is popular due to its simplicity and web UI. However, there are other tools
for testing email locally, such as:

- **MailCatcher**: Another lightweight SMTP server with a Ruby base, providing a similar web
  UI ([MailCatcher Docs](https://mailcatcher.me/)).
- **Papercut**: A cross-platform, self-hosted SMTP server with a built-in web interface and flexible
  configuration ([Papercut Docs](https://papercut-smtp.readthedocs.io/)).
- **GreenMail**: A Java-based email testing server that supports SMTP, IMAP, and POP3, useful for projects already using
  Java ([GreenMail Docs](https://greenmail-mail-test.github.io/greenmail/)).

MailHog is chosen here for its ease of integration with Docker, minimal configuration, and ability to reliably capture
emails in development.

### Production Mail-Sending Options

For production environments, it’s crucial to use a reliable SMTP service rather than a testing tool like MailHog.
Popular production-ready email providers include:

- **SendGrid** ([SendGrid Docs](https://docs.sendgrid.com/))
- **Amazon SES** ([Amazon SES Docs](https://aws.amazon.com/ses/))
- **Mailgun** ([Mailgun Docs](https://www.mailgun.com/))

These providers offer scalable, secure options for sending transactional emails in production.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Directory Structure](#directory-structure)
3. [Configuration](#configuration)
4. [Setup Instructions](#setup-instructions)
5. [Testing the Setup](#testing-the-setup)
6. [Healthcheck Explanation](#healthcheck-explanation)
7. [Docker Commands](#docker-commands)
8. [Docker Bridge Network](#docker-bridge-network)

---

## Prerequisites

- **Docker** and **Docker Compose**: Ensure Docker and Docker Compose are installed on your system.
    - [Install Docker](https://docs.docker.com/get-docker/)
    - [Install Docker Compose](https://docs.docker.com/compose/install/)

---

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

## Directory Structure

Your project directory should look something like this:

```plaintext
project-root/
    └── mailhog
       ├── .env                       # Environment variables for Docker Compose
       ├── docker-compose.yml         # Docker Compose file to spin up services
       └── README.md                  # Project documentation (this file)
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

# Configuration

## 1. Environment Variables (.env)

Define the following environment variables in the `.env` file to customize the MailHog service:

```plaintext
# MailHog SMTP Settings
MAILHOG_HTTP_PORT=8025
MAILHOG_SMTP_PORT=1025
MAILHOG_SMTP_HOST=mailhog
MAILHOG_SMTP_FROM=no-reply@mailhog.com
MAILHOG_SMTP_FROM_DISPLAY_NAME=Support

# Healthcheck settings for MailHog
MAILHOG_HEALTHCHECK_INTERVAL=30s
MAILHOG_HEALTHCHECK_TIMEOUT=10s
MAILHOG_HEALTHCHECK_RETRIES=5
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

## 2. Docker Compose (`docker-compose.yml`)

The `docker-compose.yml` file defines the MailHog service:

```yaml
services:
  mailhog:
    image: mailhog/mailhog:v1.0.1
    container_name: ${MAILHOG_SMTP_HOST}
    ports:
      - "${MAILHOG_WEB_PORT:-8025}:8025"
      - "${MAILHOG_SMTP_PORT:-1025}:1025"
    healthcheck:
      test: [ "CMD", "sh", "-c", "nc -z localhost 8025" ]
      interval: ${MAILHOG_HEALTHCHECK_INTERVAL:-30s}
      timeout: ${MAILHOG_HEALTHCHECK_TIMEOUT:-10s}
      retries: ${MAILHOG_HEALTHCHECK_RETRIES:-5} #ignore the intellij error
    networks:
      - keycloak_network

networks:
  keycloak_network:
    driver: bridge
    name: keycloak_network
```

- **image**: Specifies the Docker image to use (`mailhog/mailhog:v1.0.1`).
- **container_name**: Sets the container name to the value of `MAILHOG_SMTP_HOST`, defined in `.env`.
- **ports**: Maps the SMTP port (`1025`) and HTTP port (`8025`) to your host system, allowing you to access MailHog on
  `localhost`:
    - **MAILHOG_HTTP_PORT**: The port to access MailHog's web interface.
    - **MAILHOG_SMTP_PORT**: The port to use MailHog as an SMTP server.
- **healthcheck**: Configures a health check using Netcat to ensure that MailHog’s SMTP service is responsive (explained
  in detail below).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

## MailHog Configuration

- **MailHog Ports**: MailHog listens on port `8025` for the web interface and `1025` for SMTP.
- **Healthcheck**: Ensures MailHog is reachable by checking if port `8025` is open.

## Setup Instructions

### 1. Run the Services

Run the following command to start MailHog and any associated services:

```bash
./start.sh
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

#### This Command Will:

- Cleans up all containers, volumes, network before starting which are defined in the `docker-compose.yml` file.
- Start all the services defined in the `docker-compose.yml` file in detached mode (`-d`).
- Connect all services through the defined `keycloak_network`.
- Start the MailHog container in detached mode.
- Expose port `8025` for the web interface and `1025` for SMTP.
- Perform healthchecks to ensure MailHog is up and running.

You can also use:

```bash
docker-compose up -d
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### 2. Access MailHog Web Interface

Once the service is running, you can access the MailHog web interface at:

[http://localhost:8025](http://localhost:8025)

You can view all the emails captured by MailHog through this interface. This is useful for testing applications that
send emails, like Keycloak.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Testing the Setup

After the container is up, verify the following:

1. **Access the MailHog web interface**:

- Open your browser and go to `http://localhost:<MAILHOG_HTTP_PORT>` (default port is `8025`).
- This interface allows you to view and manage captured emails.

2. **Send a test email**:

- Use an SMTP client or application configured to send emails to `MAILHOG_SMTP_HOST` and `MAILHOG_SMTP_PORT` (default is
  `localhost:1025`).
- Check if the email appears in the MailHog web interface.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

## Healthcheck Explanation

The healthcheck in the `docker-compose.yml` file ensures that the MailHog container is running and able to respond to
requests.

```yaml
healthcheck:
  test: [ "CMD", "sh", "-c", "nc -z localhost 8025" ]
  interval: ${MAILHOG_HEALTHCHECK_INTERVAL:-30s}
  timeout: ${MAILHOG_HEALTHCHECK_TIMEOUT:-10s}
  retries: ${MAILHOG_HEALTHCHECK_RETRIES:-5}
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Details:

- **nc (Netcat)**: A versatile command for network troubleshooting. This command uses Netcat (`nc`), a networking
  utility, with the `-z` option to perform a "zero I/O mode" check, essentially probing the specified port to see if
  it's open and accepting connections. For more information, see [Netcat Documentation](https://linux.die.net/man/1/nc).
- **nc -z localhost 8025**: Checks if port `8025` (MailHog’s web interface) is open and accepting connections on
  `localhost`. The `-z` flag makes `nc` only test the port without sending data.
    - If the port is open, MailHog is reachable, and the healthcheck passes.
    - If the port is closed, the healthcheck fails, and Docker rechecks based on the interval, timeout, and retry
      settings.

For more details on health checks in Docker, refer to
the [Docker Healthcheck Documentation](https://docs.docker.com/engine/reference/builder/#healthcheck).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

## Docker Commands

### Run the MailHog Service

To start MailHog in detached mode:

```bash
docker-compose up -d
```

### Stop the MailHog Service

To stop the service:

```bash
docker-compose down
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Remove Containers, Volumes, and Networks

To remove MailHog and its associated volumes and networks:

```bash
docker-compose down --volumes --remove-orphans
```

### View Logs

To view the logs for MailHog:

```bash
docker-compose logs -f mailhog
```

### Start Services Again

If the services were stopped, you can restart them using:

```bash
docker-compose start
```

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

## Docker Bridge Network

In Docker, containers are connected to networks to allow communication between them. The `bridge` network is the default
network driver for containers.

For more information, see [Docker Networking Overview](https://docs.docker.com/network/).

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)

### Why use the bridge network?

The `bridge` network allows containers to communicate with each other and with the host system. By using this network
driver, we ensure that `MailHog` (specified by `MAILHOG_SMTP_HOST`) is accessible to other containers (like Keycloak)
and the host system for testing.

In our setup, the `keycloak_network` is defined with the `bridge` driver, ensuring that MailHog can interact with other
services in the Docker environment.

For example, if `MAILHOG_SMTP_HOST=mailhog`, other containers on the same Docker network can send emails by pointing
their SMTP settings to `mailhog` on port `1025`.

```yaml
networks:
  keycloak_network:
    driver: bridge
```

This network setup is crucial for the communication between services, especially when running multiple containers in an
isolated environment.

By following this guide, you will have MailHog set up and running in your development environment for testing email
functionality.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](../README.md)
