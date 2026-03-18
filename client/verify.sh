#!/bin/bash
# Run from mini-ca/ root directory
# Usage: bash client/verify.sh <host:port>

HOST=$1

echo "=== Подключение к $HOST ==="
openssl s_client -connect $HOST -CAfile client/root.crt 2>&1 | grep -E "Verify|error"
