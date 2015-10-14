#!/bin/bash
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to create sample certificates for the dart:io SecureSocket tests.
# Creates a root certificate authority, an intermediate authority,
# and a server certificate,

password=pass:dartdart

# We need a server certificate chain where we don't trust the root.  Take the
# server certificate from the previous run of this script, for that purpose.
if [ -d "certificates" ]; then
  mv certificates/server_key.pem certificates/untrusted_server_key.pem
  mv certificates/server_chain.pem certificates/untrusted_server_chain.pem
else
  mkdir certificates
fi

mkdir -p certificate_authority
cd certificate_authority

# Create a self-signed certificate authority.
openssl req -subj /CN=rootauthority -set_serial 1 -batch -verbose \
    -passout $password -new -x509 -keyout root_authority_key.pem \
    -out root_authority.pem -days 3650

# Create a certificate request for the intermediate authority.
openssl req -subj /CN=intermediateauthority -batch -verbose \
    -passout $password -new -keyout intermediate_authority_key.pem \
    -out intermediate_authority_request.pem

# Sign the certificate of the intermediate authority with the root authority.
# Add the certificate extensions marking it as a certificate authority.
openssl x509 -req -in intermediate_authority_request.pem \
    -out intermediate_authority.pem -set_serial 1 \
    -CA root_authority.pem -CAkey root_authority_key.pem \
    -passin $password -extfile ../intermediate_authority_v3_extensions \
    -days 3650

# Create a certificate request for the server certificate
openssl req -subj /CN=localhost -batch -verbose -passout $password -new \
    -keyout localhost_key.pem -out localhost_request.pem

# Sign the server certificate  with the intermediate authority.  Add the
# certificate extensions for SubjectAltName and that it is not a CA itself.
openssl x509 -req -in localhost_request.pem -out localhost.pem -set_serial 1 \
    -CA intermediate_authority.pem -CAkey intermediate_authority_key.pem \
    -passin $password -extfile ../localhost_v3_extensions -days 3650

cat localhost.pem intermediate_authority.pem root_authority.pem \
    > ../certificates/server_chain.pem

# BoringSSL only accepts private keys signed with the PBE-SHA1-RC4-128 cipher.
openssl pkcs8 -in localhost_key.pem -out ../certificates/server_key.pem \
    -topk8 -v1 PBE-SHA1-RC4-128 -passin $password -passout $password

cp root_authority.pem ../certificates/trusted_certs.pem

cd ..
