# Apache and Keycloak Reverse Proxy Configuration

This project contains Apache HTTP server configuration files to set up a reverse proxy for Keycloak, a popular
open-source identity and access management solution. These configurations allow Apache to forward requests to a running
Keycloak instance, enabling secure and seamless integration between the Apache server and Keycloak.

---

# Table of Contents

1. [Overview](#overview)
2. [httpd.conf - Apache HTTP Server Configuration](#httpdconf---apache-http-server-configuration)
    - [Key Definitions](#key-definitions)
    - [Important Sections](#important-sections)
3. [keycloak-reverse-proxy.conf - Keycloak Reverse Proxy Configuration](#keycloak-reverse-proxyconf---keycloak-reverse-proxy-configuration)
    - [Key Definitions](#key-definitions-1)
    - [Key Features](#key-features)
4. [Keycloak Reverse Proxy Path Recommendations](#keycloak-reverse-proxy-path-recommendations)
5. [Securing the "admin/" Path](#securing-the-admin-path)
6. [How to Use](#how-to-use)
    - [Configure Apache](#configure-apache)
    - [Set Environment Variables](#set-environment-variables)
    - [Start Apache](#start-apache)
7. [Troubleshooting](#troubleshooting)
8. [Conclusion](#conclusion)

---

## Overview

1. **httpd.conf**: The main Apache configuration file that defines the general server settings, including timeouts,
   logging, security settings, and reverse proxy configuration for Keycloak.
2. **keycloak-reverse-proxy.conf**: Contains the reverse proxy configuration specifically for Keycloak, ensuring that
   requests to Keycloak's endpoints are correctly routed.

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## **httpd.conf** - Apache HTTP Server Configuration

This is the main Apache configuration file, which contains several important settings:

### Key Definitions

- **SERVER_PORT**: Defines the port that Apache will listen on (default is 80 for HTTP).
- **SERVER_NAME**: The domain or hostname of your server (e.g., `localhost`).
- **SERVER_ADMIN**: The email address of the server administrator.
- **DOCUMENT_ROOT**: The root directory for serving static content.
- **LOGS**: Defines log files for access and error logs.

### Important Sections

1. **Server Settings**: The `ServerName`, `ServerAdmin`, and logging settings (`ErrorLog`, `CustomLog`) define the
   general server behavior and log rotation settings.
2. **Timeout Settings**: These control the timeout values for requests to prevent hanging requests.
3. **Security**:
    - **Headers**: Sets security headers such as `X-Frame-Options`, `X-XSS-Protection`, and `Strict-Transport-Security`
      to enhance the security of your server.
    - **Directory Settings**: Controls the permissions for the document root and ensures no directory listings are
      shown.
4. **Proxy Setup**: The `IncludeOptional ${ENABLE_KEYCLOAK_CONF}` line conditionally includes the reverse proxy
   configuration for Keycloak if the `ENABLE_KEYCLOAK_PROXY` is set.
5. **Dynamic Include**: The configuration uses `IncludeOptional` to dynamically include the Keycloak reverse proxy
   configuration.

For more details on Apache HTTP configuration, check
the [official Apache HTTP Server documentation](https://httpd.apache.org/docs/2.4/).

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## **keycloak-reverse-proxy.conf** - Keycloak Reverse Proxy Configuration

This file configures Apache to act as a reverse proxy for Keycloak.

### Key Definitions

- **SERVER_IP_ADDRESS**: The server IP address where Apache will listen (default is `*` to listen on all interfaces).
- **KEYCLOAK_HOST**: The hostname or IP address of the Keycloak server.
- **KEYCLOAK_PORT**: The port on which Keycloak is running (default is `8080`).
- **KEYCLOAK_URL**: Full URL to access Keycloak, including host and port.

### Key Features

1. **Reverse Proxy Setup**:
    - Uses `ProxyPass` and `ProxyPassReverse` to forward requests from Apache to Keycloak. For example, requests to
      `/realms/` on Apache are forwarded to `/realms/` on Keycloak.
    - **ProxyPass** is responsible for sending the request to Keycloak, and **ProxyPassReverse** ensures that responses
      from Keycloak are correctly routed back to the client.

2. **Access Control**:
    - The `<LocationMatch>` block denies access to all paths except for Keycloak’s authorized URLs (e.g., `/realms/`,
      `/resources/`, and `/admin/`).

3. **Security Headers**: The configuration adds extra HTTP headers to prevent clickjacking, cross-site scripting (XSS),
   and other security vulnerabilities by setting headers like `X-Frame-Options` and `Strict-Transport-Security`.

For more information about reverse proxying with Apache, refer to
the [Apache mod_proxy documentation](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html).

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## **Keycloak Reverse Proxy Path Recommendations**

When setting up Keycloak behind a reverse proxy, it's important to ensure that certain paths are correctly exposed and
others are protected. Keycloak's documentation provides recommendations on which paths should be proxied.

For the full list of recommended paths, check out Keycloak's official
guide: [Exposed Path Recommendations](https://www.keycloak.org/server/reverseproxy#_exposed_path_recommendations).

Key paths to proxy include:

- `/realms/`
- `/resources/`
- `/robots.txt`

It is advised to secure sensitive administrative paths and only expose what is necessary for users and applications to
interact with Keycloak.

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## **Securing the "admin/" Path**

The `admin/` path in Keycloak provides access to the administrative interface and should be secured carefully to prevent
unauthorized access. Here are some steps to secure the `admin/` path:

1. **Basic Authentication**:
   You can configure Apache to require basic authentication for access to the `admin/` path using `.htpasswd` files.
   This ensures that only authorized users can access the admin console.

   Example:
   ```apache
   <Location /admin/>
     AuthType Basic
     AuthName "Restricted Area"
     AuthUserFile /path/to/.htpasswd
     Require valid-user
   </Location>
   ```

2. **IP Whitelisting**:
   Restrict access to the `admin/` path based on IP addresses. This can help prevent unauthorized users from accessing
   the admin interface.

   Example:
   ```apache
   <Location /admin/>
     Require ip 192.168.1.0/24
   </Location>
   ```

3. **TLS/SSL**:
   Always use TLS/SSL (HTTPS) for sensitive administrative paths to encrypt the traffic. Ensure that Keycloak is running
   over HTTPS and that the reverse proxy is properly configured to handle SSL termination.

   ```apache
   <VirtualHost *:443>
     SSLEngine on
     SSLCertificateFile /path/to/cert.crt
     SSLCertificateKeyFile /path/to/cert.key
     ProxyPass /admin/ https://keycloak-server:8080/admin/
     ProxyPassReverse /admin/ https://keycloak-server:8080/admin/
   </VirtualHost>
   ```

4. **Keycloak Role-based Access Control**:
   In addition to securing the path through Apache, ensure that access to the `admin/` path in Keycloak is restricted to
   users with appropriate roles (such as `admin` or `realm-admin`).

For more details on securing Keycloak’s admin interface, refer
to [Keycloak’s official security documentation](https://www.keycloak.org/docs/latest/server_admin/#_security).

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## How to Use

### Configure Apache:

- Ensure that Apache is installed and the `mod_proxy` and `mod_proxy_http` modules are enabled. These modules are
  required for reverse proxying.
- Place the `httpd.conf` and `keycloak-reverse-proxy.conf` files in the appropriate Apache configuration directories.
- Ensure that the `Enable_Keycloak_Proxy` variable is set correctly to either `true` or `false` depending on whether you
  want to enable the reverse proxy for Keycloak.

### Set Environment Variables:

- If you're using environment variables to control configurations, make sure `SETUP_KEYCLOAK_PROXY` is set to `true` in
  your environment to enable the proxy.

### Start Apache:

- Start the Apache service and check the logs to confirm that the reverse proxy is functioning correctly.

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## Troubleshooting

- **404 Errors**: Ensure that Keycloak is running on the correct host and port as specified in `KEYCLOAK_HOST` and
  `KEYCLOAK_PORT`. If Keycloak is behind a firewall or on a different network, make sure that Apache can reach it.
- **403 Forbidden**: Check the `LocationMatch` section to ensure that the appropriate paths are allowed and Keycloak is
  configured correctly to handle them.

For more troubleshooting steps, visit
the [Apache Troubleshooting Guide](https://httpd.apache.org/docs/2.4/howto/troubleshoot.html).

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---

## Conclusion

This reverse proxy setup enables a secure and scalable way to integrate Apache HTTP Server with Keycloak. By using the
`mod_proxy` module, Apache can seamlessly forward requests to Keycloak, enabling single sign-on (SSO) and centralized
authentication for your applications.

For more information on reverse proxying with Keycloak,
visit [Keycloak’s Reverse Proxy Documentation](https://www.keycloak.org/server/reverseproxy).

[Go to Table of Contents](#table-of-contents)
[Go back to Apache](../README.md)
[Go back to Project](../../README.md)

---
