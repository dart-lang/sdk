// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/server_key.p12
// OtherResources=certificates/client1_key_malformed.pem
// OtherResources=certificates/trusted_certs_malformed.pem
// OtherResources=certificates/server_chain_malformed1.pem
// OtherResources=certificates/server_chain_malformed2.pem
// OtherResources=certificates/client_authority_malformed.pem

import "package:expect/expect.dart";
import "dart:io";

String localFile(path) => Platform.script.resolve(path).toFilePath();

bool printException(e) {
  print(e);
  return true;
}

bool argumentError(e) => e is ArgumentError;
bool argumentOrTypeError(e) => e is ArgumentError || e is TypeError;
bool fileSystemException(e) => e is FileSystemException;
bool tlsException(e) => e is TlsException;

void testUsePrivateKeyArguments() {
  var c = new SecurityContext();
  c.useCertificateChain(localFile('certificates/server_chain.pem'));

  // Wrong password.
  Expect.throws(() => c.usePrivateKey(localFile('certificates/server_key.pem')),
      tlsException);
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/server_key.pem'),
          password: "iHackSites"),
      tlsException);
  Expect.throws(() => c.usePrivateKey(localFile('certificates/server_key.p12')),
      tlsException);
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/server_key.p12'),
          password: "iHackSites"),
      tlsException);
  Expect.throws(
      () => c.setTrustedCertificates(localFile('certificates/server_key.p12')),
      tlsException);
  Expect.throws(
      () => c.setTrustedCertificates(localFile('certificates/server_key.p12'),
          password: "iHackSites"),
      tlsException);
  Expect.throws(
      () => c.useCertificateChain(localFile('certificates/server_key.p12')),
      tlsException);
  Expect.throws(
      () => c.useCertificateChain(localFile('certificates/server_key.p12'),
          password: "iHackSites"),
      tlsException);
  Expect.throws(
      () => c.setClientAuthorities(localFile('certificates/server_key.p12')),
      tlsException);
  Expect.throws(
      () => c.setClientAuthorities(localFile('certificates/server_key.p12'),
          password: "iHackSites"),
      tlsException);

  // File does not exist
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/server_key_oops.pem'),
          password: "dartdart"),
      fileSystemException);

  // Wrong type for file name or data
  Expect.throws(() => c.usePrivateKey(1), argumentOrTypeError);
  Expect.throws(() => c.usePrivateKey(null), argumentError);
  Expect.throws(() => c.usePrivateKeyBytes(1), argumentOrTypeError);
  Expect.throws(() => c.usePrivateKeyBytes(null), argumentError);

  // Too-long passwords.
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/server_key.pem'),
          password: "dart" * 1000),
      argumentError);
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/server_key.p12'),
          password: "dart" * 1000),
      argumentOrTypeError);
  Expect.throws(
      () => c.setTrustedCertificates(localFile('certificates/server_key.p12'),
          password: "dart" * 1000),
      argumentOrTypeError);
  Expect.throws(
      () => c.useCertificateChain(localFile('certificates/server_key.p12'),
          password: "dart" * 1000),
      argumentOrTypeError);
  Expect.throws(
      () => c.setClientAuthorities(localFile('certificates/server_key.p12'),
          password: "dart" * 1000),
      argumentOrTypeError);

  // Bad password type.
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/server_key.pem'),
          password: 3),
      argumentOrTypeError);
  Expect.throws(
      () => c.setTrustedCertificatesBytes(
          localFile('certificates/server_key.pem'),
          password: 3),
      argumentOrTypeError);
  Expect.throws(
      () => c.useCertificateChainBytes(localFile('certificates/server_key.pem'),
          password: 3),
      argumentOrTypeError);
  Expect.throws(
      () => c.setClientAuthoritiesBytes(
          localFile('certificates/server_key.pem'),
          password: 3),
      argumentOrTypeError);

  // Empty data.
  Expect.throws(
      () => c.usePrivateKeyBytes([], password: 'dartdart'), tlsException);
  Expect.throws(() => c.setTrustedCertificatesBytes([]), tlsException);
  Expect.throws(() => c.useCertificateChainBytes([]), tlsException);
  Expect.throws(() => c.setClientAuthoritiesBytes([]), tlsException);

  // Malformed PEM certs.
  Expect.throws(
      () => c.usePrivateKey(localFile('certificates/client1_key_malformed.pem'),
          password: "dartdart"),
      tlsException);
  Expect.throws(
      () => c.setTrustedCertificates(
          localFile('certificates/trusted_certs_malformed.pem')),
      tlsException);
  Expect.throws(
      () => c.useCertificateChain(
          localFile('certificates/server_chain_malformed1.pem')),
      tlsException);
  Expect.throws(
      () => c.useCertificateChain(
          localFile('certificates/server_chain_malformed2.pem')),
      tlsException);
  Expect.throws(
      () => c.setClientAuthorities(
          localFile('certificates/client_authority_malformed.pem')),
      tlsException);
}

void main() {
  testUsePrivateKeyArguments();
}
