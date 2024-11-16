# Postman Collection for Keycloak Integration

This folder contains the Postman collection and environment files for testing the Keycloak integration.

## Folder Structure

```
 keycloak-poc-modularized
 └── postman
     ├── keycloak-local.postman_environment.json
     ├── keycloak-postman-collection.json
     └── README.md
```

## Files

1. **keycloak-local.postman_environment.json**  
   This file contains the environment configuration for Postman, including all necessary variables required to run the
   tests locally with Keycloak.

2. **keycloak-postman-collection.json**  
   This file contains the Postman collection for Keycloak-related API tests. It includes predefined requests for various
   endpoints to test the functionality of Keycloak.

## How to Import the JSON Files into Postman

To use these files in Postman, follow these steps:

1. Open Postman.
2. Click on the "Import" button in the top-left corner of the Postman window.
3. Choose the **"File"** tab.
4. Select the `keycloak-postman-collection.json` file to import the collection.
5. Similarly, select the `keycloak-local.postman_environment.json` file to import the environment.

Alternatively, you can drag and drop these files directly into Postman.

For more details on importing collections, refer to
the [official Postman documentation](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#importing-data).

## Running Tests

Once you have imported the collection and environment into Postman, you can run the tests as follows:

1. Open the imported collection in Postman.
2. Select the "Runner" button in the top-right corner.
3. Choose the appropriate environment (e.g., `keycloak-local`).
4. Click "Run" to execute the tests.

Postman will execute the requests defined in the collection and display the results.

### Running Tests with Newman (Command-Line)

Newman is the command-line companion for Postman. You can use Newman to run the Postman collection from the terminal.

1. Install Newman globally:

```bash
   npm install -g newman
```

2. Run the Postman collection with Newman:

```bash
   newman run keycloak-postman-collection.json -e keycloak-local.postman_environment.json
```

3. To generate reports, use the following command:

```bash
   newman run keycloak-postman-collection.json \
     -e keycloak-local.postman_environment.json \
     --reporters cli,html,junit \
     --reporter-html-export postman-report.html \
     --reporter-junit-export postman-report.xml
```

For more information on using Newman, refer to the [Newman documentation](https://www.npmjs.com/package/newman).

## Official Documentation

- [Postman Collection Documentation](https://learning.postman.com/docs/getting-started/introduction/)
- [Postman Environment Variables](https://learning.postman.com/docs/postman/environments-and-globals/)
- [Newman Documentation](https://www.npmjs.com/package/newman)
