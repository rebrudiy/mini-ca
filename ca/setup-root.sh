#!/bin/bash
# Run from mini-ca/ root directory

# Step 1: Root CA private key
openssl genrsa -out ca/root.key 4096

# Step 2: Self-signed root certificate (10 years)
openssl req -new -x509 -days 3650 \
  -key ca/root.key \
  -out ca/root.crt \
  -subj "/CN=Mini Root CA/O=Mini CA/C=RU"

# Step 3: Intermediate CA private key
openssl genrsa -out ca/intermediate.key 4096

# Step 4: Intermediate CA certificate request
openssl req -new \
  -key ca/intermediate.key \
  -out ca/intermediate.csr \
  -subj "/CN=Mini Intermediate CA/O=Mini CA/C=RU"

# Step 5: Sign intermediate with root (5 years)
openssl x509 -req -days 1825 \
  -in ca/intermediate.csr \
  -CA ca/root.crt \
  -CAkey ca/root.key \
  -CAcreateserial \
  -out ca/intermediate.crt

# Step 6: Initialize CA database
touch ca/index.txt
echo "1000" > ca/serial
echo "1000" > ca/crlnumber

echo "Root CA and Intermediate CA created successfully"
