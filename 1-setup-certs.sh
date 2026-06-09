#!/bin/bash
set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=================================================================\${NC}"
echo -e "${GREEN}   Phase 1: Self-Signed CA & Registry Certificate Generator      \${NC}"
echo -e "${GREEN}=================================================================\${NC}"

read -r -p "Enter Private Registry FQDN (e.g., registry.local): " REGISTRY_FQDN
if [ -z "$REGISTRY_FQDN" ]; then echo -e "${RED}Error: FQDN required.\${NC}"; exit 1; fi

OUTPUT_DIR="./nai-certs"
mkdir -p "$OUTPUT_DIR"

openssl genrsa -out "${OUTPUT_DIR}/rootCA.key" 4096
openssl req -x509 -new -nodes -key "${OUTPUT_DIR}/rootCA.key" -sha256 -days 3650 \
  -out "${OUTPUT_DIR}/rootCA.crt" -subj "/CN=Nutanix NAI Private CA/O=Nutanix/OU=SE Field Kit"

openssl genrsa -out "${OUTPUT_DIR}/registry.key" 2048

CONF_FILE="${OUTPUT_DIR}/openssl-san.cnf"
cat <<EOF > "$CONF_FILE"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = \${REGISTRY_FQDN}
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = \${REGISTRY_FQDN}
EOF

openssl req -new -key "${OUTPUT_DIR}/registry.key" -out "${OUTPUT_DIR}/registry.csr" -config "$CONF_FILE"
openssl x509 -req -in "${OUTPUT_DIR}/registry.csr" -CA "${OUTPUT_DIR}/rootCA.crt" -CAkey "${OUTPUT_DIR}/rootCA.key" \
  -CAcreateserial -out "${OUTPUT_DIR}/registry.crt" -days 1095 -sha256 -extensions v3_req -extfile "$CONF_FILE"

rm "${OUTPUT_DIR}/registry.csr" "$CONF_FILE"
echo -e "\n\${GREEN}✔ Certificates saved to: \${OUTPUT_DIR}/\${NC}"
