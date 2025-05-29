export MSYS_NO_PATHCONV=1

CERTS_DIR="../certs"
mkdir -p "$CERTS_DIR"

echo "Generating CA key and certificate..."
openssl genrsa -out "$CERTS_DIR/ca.key" 2048

openssl req -x509 -new -nodes -key "$CERTS_DIR/ca.key" \
  -sha256 -days 365 \
  -out "$CERTS_DIR/ca.crt" \
  -subj "/C=AU/ST=NSW/L=Sydney/O=example_org/CN=example.com CA"

echo "Generating LDAP server key and CSR..."
openssl genrsa -out "$CERTS_DIR/ldap.key" 2048

# Create OpenSSL config file with SAN
cat > "$CERTS_DIR/ldap_openssl.cnf" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
C  = AU
ST = NSW
L  = Sydney
O  = example_org
CN = example.com

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.0 = openldap
DNS.1 = example.com
IP.0 = 127.0.0.1
EOF

openssl req -new -key "$CERTS_DIR/ldap.key" \
  -out "$CERTS_DIR/ldap.csr" \
  -config "$CERTS_DIR/ldap_openssl.cnf"

echo "Signing LDAP server certificate with CA and SAN..."
# Create extfile for v3 extensions (for certificate signing)
cat > "$CERTS_DIR/v3_ext.cnf" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.0 = openldap
DNS.1 = example.com
IP.0 = 127.0.0.1
EOF

openssl x509 -req -in "$CERTS_DIR/ldap.csr" \
  -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERTS_DIR/ldap.crt" \
  -days 365 -sha256 \
  -extfile "$CERTS_DIR/v3_ext.cnf"

echo "Cleaning up CSR, serial, and config files..."
rm -f "$CERTS_DIR/ldap.csr" "$CERTS_DIR/ca.srl" "$CERTS_DIR/ldap_openssl.cnf" "$CERTS_DIR/v3_ext.cnf"

echo "Certificates generated in $CERTS_DIR:"
ls -l "$CERTS_DIR"
