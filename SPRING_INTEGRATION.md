# Spring Boot Integration with Keycloak

This document explains how to integrate a Java-based Spring Boot web application with Keycloak for authentication using
OAuth2/OpenID Connect.

---

## Table of Contents

1. [Spring Boot Integration with Keycloak](#spring-boot-integration-with-keycloak)
2. [🔧 Application Configuration (Spring Boot App Side)](#-application-configuration-spring-boot-app-side)
    - [Option 1: application.yml](#option-1-applicationyml)
    - [Option 2: application.properties](#option-2-applicationproperties)
    - [✅ Required Dependencies in pom.xml](#-required-dependencies-in-pomxml)
3. [🛠️ Keycloak Configuration](#-keycloak-configuration)
    - [1. Create a Client](#1-create-a-client)
    - [2. Configure the Client Settings](#2-configure-the-client-settings)
4. [🔄 Login Flow](#-login-flow)
5. [🚫 What About Logout?](#-what-about-logout)

---

## 🔧 Application Configuration (Spring Boot App Side)

You can configure your application in either `application.yml` or `application.properties`.

---

### Option 1: `application.yml`

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          # ----- OAuth2 Client Registration for the identity provider -----
          # The "registrationId" is an arbitrary name, and unique ID for this OAuth2 provider configuration.
          # e.g. 'keycloak', 'authserver', 'sso', or anything else. I'm using 'authserver' here.
          # The same "registrationId" must be used in both the 'registration' and 'provider' sections.

          authserver: # registrationId
            client-id: my-web-app
            client-secret: YOUR_SECRET
            authorization-grant-type: authorization_code

            # Callback URL Keycloak will redirect to after login.
            # Spring Boot replaces {baseUrl} and {registrationId} at runtime.
            # Example: http://localhost:8081/login/oauth2/code/authserver
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"

            scope: openid, profile, email

        provider:
          # ----- OAuth2 Provider Configuration -----
          # This section must use the same registrationId ('authserver') as above.

          authserver: # registrationId
            issuer-uri: http://localhost:8080/realms/myrealm
```

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---

### Option 2: `application.properties`

```properties
# ----- OAuth2 Client Registration for the identity provider -----
# The "registrationId" is an arbitrary name, and unique ID for this OAuth2 provider configuration.
# e.g. 'keycloak', 'authserver', 'sso', or anything else. I'm using 'authserver' here.
# The same "registrationId" must be used in both the 'registration' and 'provider' sections.
# So, all the 'spring.security.oauth2.client' properties below will follow the pattern:
# spring.security.oauth2.client.registration.{registrationId}.*
spring.security.oauth2.client.registration.authserver.client-id=my-web-app
spring.security.oauth2.client.registration.authserver.client-secret=YOUR_SECRET
spring.security.oauth2.client.registration.authserver.authorization-grant-type=authorization_code
# Callback URL Keycloak will redirect to after login.
# Spring Boot replaces {baseUrl} and {registrationId} at runtime.
# Example: http://localhost:8081/login/oauth2/code/authserver
spring.security.oauth2.client.registration.authserver.redirect-uri={baseUrl}/login/oauth2/code/{registrationId}
spring.security.oauth2.client.registration.authserver.scope=openid,profile,email
# ----- OAuth2 Provider Configuration -----
# This section must use the same registrationId ('authserver') to link to the above registration block.
# Pattern: spring.security.oauth2.client.provider.{registrationId}.*
spring.security.oauth2.client.provider.authserver.issuer-uri=http://localhost:8080/realms/myrealm
```

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---

### ✅ Required Dependencies in `pom.xml`

```pom.xml

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---

## 🛠️ Keycloak Configuration

### 1. Create a Client

Go to **Keycloak Admin Console → Clients → Create**:

| Setting         | Value            |
|-----------------|------------------|
| Client ID       | `my-web-app`     |
| Client Protocol | `openid-connect` |
| Client Type     | `Confidential`   |

Click **Save**.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---

### 2. Configure the Client Settings

After saving, configure the client settings as follows:

| Setting                      | Value                                                   |
|------------------------------|---------------------------------------------------------|
| Enabled                      | ✅ ON                                                    |
| Standard Flow Enabled        | ✅ ON (required for Authorization Code flow)             |
| Direct Access Grants Enabled | ❌ OFF (not needed)                                      |
| Root URL                     | `http://localhost:8081/` (your app’s base URL)          |
| Valid Redirect URIs          | `http://localhost:8081/login/oauth2/code/authserver`    |
| Base URL                     | `http://localhost:8081/`                                |
| Admin URL (optional)         | `http://localhost:8081/logout` (if using single logout) |

> 📌 **Note:** Replace `8081` with your actual web app port.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---

## 🔄 Login Flow

1. User accesses a protected page in your Spring Boot app.
2. Spring Security redirects them to the Keycloak login page.
3. After successful login, Keycloak redirects back to your app at the specified redirect URI.
4. Spring processes the token and authenticates the user.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---

## 🚫 What About Logout?

Logout integration (especially Single Logout with Keycloak) involves some extra configuration and will be handled later.
For now, this setup supports login and session management.

[Go to Table of Contents](#table-of-contents)
[Go back to Project](./README.md)

---
