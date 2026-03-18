#!/bin/bash
# Run from mini-ca/ root directory

TMPCONF=$(mktemp)
cat > $TMPCONF << EOF
[ca]
default_ca = CA_default
[CA_default]
database          = ca/index.txt
certificate       = ca/root.crt
private_key       = ca/root.key
crlnumber         = ca/crlnumber
default_md        = sha256
default_crl_days  = 30
EOF

# Revoke intermediate certificate
openssl ca -config $TMPCONF -revoke ca/intermediate.crt

# Generate CRL
openssl ca -config $TMPCONF -gencrl -out ca/crl.pem

rm $TMPCONF

echo "Intermediate CA revoked, CRL generated: ca/crl.pem"
