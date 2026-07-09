#!/usr/bin/env bash
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
    -out intermediate_authority.pem -set_serial 2 \
    -CA root_authority.pem -CAkey root_authority_key.pem \
    -passin $password -extfile ../sample_certificate_v3_extensions \
    -extensions intermediate_authority -days 3650

# Create a certificate request for the server certificate
openssl req -subj /CN=localhost -batch -verbose -passout $password -new \
    -keyout localhost_key.pem -out localhost_request.pem

openssl req -subj /CN=badlocalhost -batch -verbose -passout $password -new \
    -keyout badlocalhost_key.pem -out badlocalhost_request.pem

# Sign the server certificate with the intermediate authority.  Add the
# certificate extensions for SubjectAltName and that it is not a CA itself.
openssl x509 -req -in localhost_request.pem -out localhost.pem -set_serial 1 \
    -CA intermediate_authority.pem -CAkey intermediate_authority_key.pem \
    -passin $password -extfile ../sample_certificate_v3_extensions \
    -extensions localhost -days 3650

openssl x509 -req -in badlocalhost_request.pem -out badlocalhost.pem -set_serial 1 \
    -CA intermediate_authority.pem -CAkey intermediate_authority_key.pem \
    -passin $password -extfile ../sample_certificate_v3_extensions \
    -extensions badlocalhost -days 3650

# Create a self-signed client certificate authority.
openssl req -subj /CN=clientauthority -set_serial 1 -batch -verbose \
    -passout $password -new -x509 -keyout client_authority_key.pem \
    -out client_authority.pem -config ../sample_certificate_v3_extensions \
    -extensions client_authority -days 3650

# Create certificate requests for the client certificates
openssl req -subj /CN=user1 -batch -verbose -passout $password -new \
    -keyout client1_key.pem -out client1_request.pem
openssl req -subj /CN=user2 -batch -verbose -passout $password -new \
    -keyout client2_key.pem -out client2_request.pem

# Sign the certificate requests with the client authority
openssl x509 -req -in client1_request.pem -out client1.pem -set_serial 2 \
    -CA client_authority.pem -CAkey client_authority_key.pem \
    -passin $password -extfile ../sample_certificate_v3_extensions \
    -extensions client_certificate -days 3650
openssl x509 -req -in client2_request.pem -out client2.pem -set_serial 3 \
    -CA client_authority.pem -CAkey client_authority_key.pem \
    -passin $password -extfile ../sample_certificate_v3_extensions \
    -extensions client_certificate -days 3650

# Copy the certificates we will use to the 'certificates' directory.
CERTS=../certificates
cat localhost.pem intermediate_authority.pem root_authority.pem \
    > $CERTS/server_chain.pem

cat badlocalhost.pem intermediate_authority.pem root_authority.pem \
    > $CERTS/bad_server_chain.pem

cat intermediate_authority.pem root_authority.pem client_authority.pem \
    > $CERTS/server_trusted.pem

# BoringSSL only accepts private keys signed with the PBE-SHA1-RC4-128 cipher.
openssl pkcs8 -in localhost_key.pem -out $CERTS/server_key.pem \
    -topk8 -v1 PBE-SHA1-RC4-128 -passin $password -passout $password
openssl pkcs8 -in badlocalhost_key.pem -out $CERTS/bad_server_key.pem \
    -topk8 -v1 PBE-SHA1-RC4-128 -passin $password -passout $password
openssl pkcs8 -in client1_key.pem -out $CERTS/client1_key.pem \
    -topk8 -v1 PBE-SHA1-RC4-128 -passin $password -passout $password
openssl pkcs8 -in client2_key.pem -out $CERTS/client2_key.pem \
    -topk8 -v1 PBE-SHA1-RC4-128 -passin $password -passout $password

# Delete all the signing keys for the authorities, so testers that add
# them as trusted are less vulnerable: only the sample server certificate
# and client certificates will be signed by them. No more certificates
# will ever be signed.
rm root_authority_key.pem
rm intermediate_authority.pem
rm client_authority_key.pem

cp root_authority.pem $CERTS/trusted_certs.pem
cp client_authority.pem $CERTS
cp client1.pem $CERTS
cp client2.pem $CERTS

cd ..
