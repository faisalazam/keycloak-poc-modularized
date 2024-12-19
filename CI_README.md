# CI/CD Workflow for Keycloak Integration

This repository contains a Continuous Integration and Continuous Deployment (CI/CD) workflow using GitHub Actions for
testing and deploying a Keycloak-based system with Docker, Postman, and GitHub Pages.

## Table of Contents

- [Workflow Overview](#workflow-overview)
- [Workflow Jobs](#workflow-jobs)
    - [Build Job](#build-job)
    - [Deploy to GitHub Pages](#deploy-to-github-pages)
- [Enabling GitHub Pages](#enabling-github-pages)
- [Key Environment Variables](#key-environment-variables)
- [Key Steps](#key-steps)
    - [1. Checkout Repository](#1-checkout-repository)
    - [2. Set SITE_ROOT_URL Variable](#2-set-site_root_url-variable)
    - [3. Cache Docker Images](#3-cache-docker-images)
    - [4. Install Docker and Docker Compose](#4-install-docker-and-docker-compose)
    - [5. Run Postman Tests with Newman](#5-run-postman-tests-with-newman)
    - [6. Deploy to GitHub Pages](#6-deploy-to-github-pages)
    - [7. Update README with Dynamic Badge](#7-update-readme-with-dynamic-badge)
- [Conclusion](#conclusion)

## Workflow Overview

The `ci.yml` file defines the CI/CD process that runs when changes are pushed to the `master` branch. The main steps
include:

1. **Checkout the repository**
2. **Install dependencies (Docker, Docker Compose, Node.js, npm, Newman)**
3. **Start services with `docker-compose`**
4. **Run Postman tests**
5. **Collect logs from Docker containers**
6. **Generate and upload test reports (HTML, XML)**
7. **Deploy reports to GitHub Pages**

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

## Workflow Jobs

### Build Job
    - Runs on `ubuntu-24.04` virtual machine.
    - Caches Docker images and npm dependencies to speed up subsequent runs.
    - Validates the presence of necessary Postman files (`POSTMAN_COLLECTION`, `POSTMAN_ENVIRONMENT`).
    - Installs Docker and Docker Compose using specific versions defined in the environment variables.
    - Starts the Docker services using `docker-compose` and `start.sh`.
    - Runs Newman to execute Postman tests.
    - Collects logs from Keycloak, MailHog, OpenLDAP, and other containers.
    - Prepares HTML and XML test reports with build metadata.
    - Uploads the reports to GitHub Pages.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### Deploy to GitHub Pages
    - Deploys the generated reports and updates the README file with dynamic badge status indicating the test result.
    - Deploys to GitHub Pages using the `github-pages-deploy-action`.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

## Enabling GitHub Pages

To enable GitHub Pages for this repository:

1. Go to your repository on GitHub.
2. Click on the **Settings** tab.
3. Scroll down to the **Pages** section in the left-hand menu.
4. Under **Source**, select the branch you are using (e.g., `master` or `main`) and the folder (`/root` or `/docs`).
5. Click **Save**.
6. GitHub Pages will provide a link to access the published site. Use this URL for viewing your reports.

Once enabled, GitHub Actions will automatically deploy the reports to this site after each successful workflow run.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

## Key Environment Variables

The following environment variables are defined in the workflow to control versions and file paths:

- `NPM_VERSION`: [Node.js version](https://nodejs.org/)
- `NEWMAN_VERSION`: [Newman version](https://www.npmjs.com/package/newman)
- `DOCKER_VERSION`: [Docker version](https://docs.docker.com/get-docker/)
- `DOCKER_COMPOSE_VERSION`: [Docker Compose version](https://docs.docker.com/compose/)
- `POSTMAN_COLLECTION`: Inside the postman folder for testing.
- `POSTMAN_ENVIRONMENT`: Inside the postman folder for testing.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

## Key Steps

### 1. Checkout Repository

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

This step checks out the repository to the GitHub Actions runner, making it available for subsequent steps.

**Official Docs**: [actions/checkout](https://github.com/actions/checkout)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### 2. Set SITE_ROOT_URL Variable

```yaml
- name: Set SITE_ROOT_URL Variable
  run: echo "SITE_ROOT_URL=https://${GITHUB_ACTOR}.github.io/${GITHUB_REPOSITORY#*/}" >> $GITHUB_ENV
```

This step sets the `SITE_ROOT_URL` variable, which is used later to reference the GitHub Pages URL.

**Official Docs**: [GitHub Actions Environment Variables](https://docs.github.com/en/actions)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### 3. Cache Docker Images

```yaml
- name: Cache Docker images
  uses: actions/cache@v4
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-docker-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-docker-
```

Caches Docker images to speed up the build process.

**Official Docs**: [actions/cache](https://github.com/actions/cache)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### 4. Install Docker and Docker Compose

```yaml
- name: Install Docker with specific version
  run: ./install_docker.sh
```

Installs Docker on the GitHub Actions runner.

**Official Docs**: [Install Docker](https://docs.docker.com/get-docker/)

```yaml
- name: Install Docker Compose with specific version
  run: |
  sudo curl -L "https://github.com/docker/compose/releases/download/v${{ env.DOCKER_COMPOSE_VERSION }}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version
  Installs Docker Compose with the specified version.
```

**Official Docs**: [Install Docker Compose](https://docs.docker.com/compose/install)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### 5. Run Postman Tests with Newman

```yaml
- name: Run Postman tests with Newman
  id: test-results
  run: |
    newman run ${{ env.POSTMAN_COLLECTION }} \
      -e ${{ env.POSTMAN_ENVIRONMENT }} \
      --reporters cli,html,junit \
      --reporter-html-export ${{ env.NEWMAN_HTML_REPORT_FILE }} \
      --reporter-junit-export ${{ env.NEWMAN_XML_REPORT_FILE }}
```

Runs the Postman tests using Newman.

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### 6. Deploy to GitHub Pages

```yaml
- name: Deploy to GitHub Pages 🚀
  uses: JamesIves/github-pages-deploy-action@v4
  with:
    folder: ${{ env.PAGES_FOLDER }}
```

Deploys the generated reports as well as the README.md to GitHub Pages.

**Official Docs**: [github-pages-deploy-action](https://github.com/JamesIves/github-pages-deploy-action)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

### 7. Update README with Dynamic Badge

```yaml
- name: Update README with dynamic badge status
  run: |
    if [ "${{ needs.build.outputs.test_outcome }}" == "success" ]; then
      BADGE="passing-brightgreen"
    else
      BADGE="failing-red"
    fi
    BADGE_MARKDOWN="[![Build Status](https://img.shields.io/badge/build-${BADGE})](${{ env.SITE_ROOT_URL }}/${{ env.NEWMAN_HTML_REPORT_FILE }})"
    echo "Badge MARKDOWN: ${BADGE_MARKDOWN}"
    sed -i "s|<!-- BUILD_BADGE_PLACEHOLDER -->|${BADGE_MARKDOWN}|g" "${{ env.PAGES_FOLDER }}/README.md"
```

Updates the README.md file with a dynamic badge indicating whether the build succeeded or failed.

**Official Docs**: [Shields.io](https://shields.io/)

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)

## Conclusion

This CI/CD workflow automates the testing, reporting, and deployment process for Keycloak and related services, ensuring
that you always have up-to-date test results available via GitHub Pages.

For more information, refer to the official documentation of the relevant tools used in this workflow:

- **[GitHub Actions Documentation](https://docs.github.com/actions)**
- **[Docker Documentation](https://docs.docker.com)**
- **[Newman Documentation](https://learning.postman.com/docs/running-collections/using-newman/command-line-integration/)**
- **[Postman Documentation](https://learning.postman.com/docs/getting-started/introduction/)**
- **[Shields.io Documentation](https://shields.io/)**

[Go to Table of Contents](#table-of-contents)  
[Go back to Project](README.md)
