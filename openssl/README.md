# Self-Signed Certificate Generation Script

This script generates a self-signed Root CA certificate and server certificates, mimicking a real-world production
environment. It ensures that the certificates follow industry standards for TLS configurations.

## **Features**

- Generates a self-signed Root CA certificate.
- Creates server certificates signed by the Root CA.
- Combines the server and Root CA certificates into a full chain.
- Validates the generated certificates for correctness.

## **Requirements**

- OpenSSL installed on the host.
- Shell interpreter supporting POSIX `sh`.

## **Usage**

1. Clone the repository and navigate to the script directory.
2. Configure the necessary parameters in `keycloak-poc-modularized/scripts/generate_certificate.sh` and
   `keycloak-poc-modularized/openssl/config/*.cnf` files.
3. Run the script:

```sh
cd keycloak-poc-modularized/scripts
./generate_certificate.sh
```

## **Directory Structure**

- `certs/`: Contains generated certificates and keys.
- `openssl/config/`: OpenSSL configuration files.
- `scripts/`: Contains the main script file.

## **Output**

- **Root CA Certificate**:  
  `certs/certificate_authority/root/cacert.pem`

- **Intermediate CA Certificate**:  
  `certs/certificate_authority/intermediate/cacert.pem`

- **Root + Intermediate Chain**:  
  `certs/certificate_authority/certificate_chains/root_and_intermediate_chain.bundle`

- **Server Certificate & Key (OpenLDAP)**:
  - Certificate: `certs/end_entity/openldap/certificate.pem`
  - Private Key: `certs/end_entity/openldap/private_key.pem`
  - Full Chain (Intermediate + Server): `certs/end_entity/openldap/intermediate_and_leaf_chain.bundle`

- **CRLs (Certificate Revocation Lists)**:
  - Root: `certs/certificate_authority/root/crl/root_ca.crl`
  - Intermediate: `certs/certificate_authority/intermediate/crl/intermediate_ca.crl`

- **CA Database Files**:  
  Located under `certs/ca_database/`, separated into `root/` and `intermediate/` folders.

## **Validation**

- The script automatically validates:
    - The Root CA certificate.
    - The server certificate against the Root CA.
    - The full chain certificate.

## **Customization**

- Modify key size, passphrase, and expiration days in the script.
- Update SANs in `openssl/config/openldap.cnf` for your environment.

## **Sharing .p12 Files with Private Keys**

The industry standard involves:

Generating a PKCS#12 (.p12) file that includes:
The client certificate.
The private key for that certificate.
The certificate chain (including intermediate and root CA certificates if applicable).
Securely sharing the .p12 file with the intended client systems or browsers.
The .p12 format ensures that the private key, certificate, and chain are bundled in one file. The file is often
protected with a strong password to ensure secure distribution.

## **Disclaimer**

This script is for testing and development purposes. Avoid using self-signed certificates in production environments
unless absolutely necessary.

## **License**

This script is open-source and can be freely modified and distributed.
