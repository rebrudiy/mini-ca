#!/bin/bash
# Run from mini-ca/ root directory

# Start HTTPS server on port 4433
openssl s_server -accept 4433 \
  -cert server/server.crt \
  -key server/server.key \
  -cert_chain ca/intermediate.crt \
  -www
