# Apache HTTP Server - Reverse Proxy Setup

## Table of Contents

1. [Introduction to Reverse Proxy](#introduction-to-reverse-proxy)
2. [Overview of Configuration Files](#overview-of-configuration-files)
3. [Apache HTTP Server Configuration](#apache-http-server-configuration)
4. [Starting the Apache Server](#starting-the-apache-server)
5. [Basic Apache Commands and Troubleshooting](#basic-apache-commands-and-troubleshooting)
6. [Links to Official Documentation](#links-to-official-documentation)

## Introduction to Reverse Proxy

A **reverse proxy** is a server that acts as an intermediary for requests from clients seeking resources from a backend
server. The Apache HTTP Server is configured here as a reverse proxy to forward requests to Keycloak, an identity and
access management system. By using a reverse proxy, you can centralize security, simplify access control, and
potentially distribute load across multiple backend services.

In this setup, the Apache HTTP Server forwards requests to Keycloak using the `ProxyPass` and `ProxyPassReverse`
directives, ensuring that both incoming requests and response headers are correctly managed.

For more information, see
the [Apache Reverse Proxy Documentation](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html).

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Overview of Configuration Files

This folder contains configurations for setting up Apache HTTP Server as a reverse proxy for Keycloak. Below is an
explanation of the files in the `apache-server` folder:

- **docker-compose.yml**: Defines the Apache HTTP Server service, configures it to forward traffic to Keycloak, and
  manages environment variables and health checks.

- **.env**: Contains environment variables such as the HTTPD port, container name, and health check configurations.

- **conf/**: Contains Apache configuration files to set up the reverse proxy.
    - **httpd.conf**: General Apache configuration.
    - **keycloak-reverse-proxy.conf**: Specific reverse proxy configuration for Keycloak, using `ProxyPass` and
      `ProxyPassReverse`.
    - **[conf/README.md](./conf/README.md)**: Provides further explanation of the configurations within the `conf/`
      folder.

- **start.sh**: Runs Docker Compose to start the Apache HTTP Server container.

- **startup_script.sh**: A shell script that runs when the Apache HTTP Server container starts. It configures the
  reverse proxy dynamically based on the `SETUP_KEYCLOAK_PROXY` environment variable.

    ```sh
    #!/bin/sh

    if [ "$SETUP_KEYCLOAK_PROXY" = "true" ]; then
      echo "Define ENABLE_KEYCLOAK_PROXY" >> /usr/local/apache2/conf/extra/enable-keycloak.conf
      echo "SUCCESS: ENABLE_KEYCLOAK_PROXY defined in enable-keycloak.conf"
    else
      echo "" > /usr/local/apache2/conf/extra/enable-keycloak.conf
      echo "SUCCESS: Cleared enable-keycloak.conf as SETUP_KEYCLOAK_PROXY is not true"
    fi

    # Start Apache
    echo "Starting Apache..."
    httpd-foreground && echo "SUCCESS: Apache started successfully" || echo "FAILURE: Apache failed to start"
    ```

    - If the `SETUP_KEYCLOAK_PROXY` variable is set to `"true"`, the script defines the `ENABLE_KEYCLOAK_PROXY`
      directive in Apache's configuration.
    - If the variable is not `"true"`, the script clears the configuration, preventing the proxy setup from being
      enabled.
    - Finally, it starts Apache using `httpd-foreground` and logs success or failure.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Apache HTTP Server Configuration

The Apache HTTP Server is configured to act as a reverse proxy for the Keycloak server. Below is an explanation of the
relevant Apache directives used in this setup:

- **ProxyPass**: This directive forwards client requests to a specified backend server (Keycloak in this case). For
  example:

  ```apache
  ProxyPass / http://keycloak:8080/
  ProxyPassReverse / http://keycloak:8080/
  ```

- **ProxyPassReverse**: This ensures that response headers from the backend server are properly rewritten before being
  sent to the client. This is necessary to maintain correct routing when the client receives a response from the
  backend.

For detailed configuration of the reverse proxy setup, please refer to
the [Apache Reverse Proxy Documentation](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html).

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Starting the Apache Server

To start the Apache HTTP Server, run the following command:

```bash
./start.sh
```

This will initialize the Docker container for the Apache HTTP server, which will automatically configure itself based on
the `SETUP_KEYCLOAK_PROXY` environment variable and start the server.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Basic Apache Commands and Troubleshooting

### Commands for Windows

- **Start Apache**: Use the `httpd.exe` command from the Apache installation directory.
- **Stop Apache**: Use `httpd.exe -k stop`.
- **Restart Apache**: Use `httpd.exe -k restart`.

### Commands for Linux

- **Start Apache**: `sudo systemctl start apache2` or `httpd`.
- **Stop Apache**: `sudo systemctl stop apache2` or `httpd`.
- **Restart Apache**: `sudo systemctl restart apache2` or `httpd`.

### Troubleshooting

1. **Check Logs**: Examine logs for errors in `/usr/local/apache2/logs/` (Docker) or `/var/log/apache2/` (Linux).
2. **Configuration Test**: Run `apachectl configtest` to ensure there are no syntax errors in your configuration files.
3. **Validate Proxy Settings**: Ensure that `ProxyPass` and `ProxyPassReverse` directives are correctly pointing to
   Keycloak.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

## Links to Official Documentation

- [Apache HTTP Server Reverse Proxy Module](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html)
- [Keycloak Official Documentation](https://www.keycloak.org/documentation)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)

---

This setup ensures that your Apache HTTP Server functions as a reverse proxy for Keycloak, providing a clean, secure,
and scalable way to manage traffic to your identity and access management service.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](../README.md)
