# CI/CD Workflow for Keycloak Integration

This repository contains a Continuous Integration and Continuous Deployment (CI/CD) workflow using GitHub Actions for testing and deploying a Keycloak-based system with Docker, Postman, and GitHub Pages.

## Workflow Overview

The `ci.yml` file defines the CI/CD process that runs when changes are pushed to the `master` branch. The main steps include:

1. **Checkout the repository**
2. **Install dependencies (Docker, Docker Compose, Node.js, npm, Newman)**
3. **Start services with `docker-compose`**
4. **Run Postman tests**
5. **Collect logs from Docker containers**
6. **Generate and upload test reports (HTML, XML)**
7. **Deploy reports to GitHub Pages**

### Workflow Jobs

1. **Build Job**
    - Runs on `ubuntu-latest` virtual machine.
    - Caches Docker images and npm dependencies to speed up subsequent runs.
    - Validates the presence of necessary Postman files (`POSTMAN_COLLECTION`, `POSTMAN_ENVIRONMENT`).
    - Installs Docker and Docker Compose using specific versions defined in the environment variables.
    - Starts the Docker services using `docker-compose` and `start.sh`.
    - Runs Newman to execute Postman tests.
    - Collects logs from Keycloak, MailHog, OpenLDAP, and other containers.
    - Prepares HTML and XML test reports with build metadata.
    - Uploads the reports to GitHub Pages.

2. **Deploy to GitHub Pages**
    - Deploys the generated reports and updates the README file with dynamic badge status indicating the test result.
    - Deploys to GitHub Pages using the `github-pages-deploy-action`.

## Key Environment Variables

The following environment variables are defined in the workflow to control versions and file paths:

- `NPM_VERSION`: [Node.js version](https://nodejs.org/)
- `NEWMAN_VERSION`: [Newman version](https://www.npmjs.com/package/newman)
- `DOCKER_VERSION`: [Docker version](https://docs.docker.com/get-docker/)
- `DOCKER_COMPOSE_VERSION`: [Docker Compose version](https://docs.docker.com/compose/)
- `POSTMAN_COLLECTION`: Path to the Postman collection for testing.
- `POSTMAN_ENVIRONMENT`: Path to the Postman environment file for testing.

## Key Steps

### 1. Checkout Repository

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

