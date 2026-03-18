#!/bin/bash
# Run from mini-ca/ root directory

# Sign server CSR with intermediate CA
openssl x509 -req -days 365 \
  -in server/server.csr \
  -CA ca/intermediate.crt \
  -CAkey ca/intermediate.key \
  -CAcreateserial \
  -out server/server.crt

echo "Server certificate signed successfully"
