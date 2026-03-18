#!/bin/bash
# Run from mini-ca/ root directory

# Step 1: Server private key
openssl genrsa -out server/server.key 2048

# Step 2: Certificate signing request
openssl req -new \
  -key server/server.key \
  -out server/server.csr \
  -subj "/CN=localhost/O=Mini CA/C=RU"

echo "Server key and CSR created successfully"
