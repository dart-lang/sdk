// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

String localFile(path) => Platform.script.resolve(path).toFilePath();

bool printException(e) { print(e); return true; }
bool argumentError(e) => e is ArgumentError;
bool argumentOrTypeError(e) => e is ArgumentError || e is TypeError;
bool fileSystemException(e) => e is FileSystemException;
bool tlsException(e) => e is TlsException;

void testUsePrivateKeyArguments() {
    var c = new SecurityContext();
    c.useCertificateChainSync(localFile('certificates/server_chain.pem'));
    Expect.throws(() => c.usePrivateKeySync(
        localFile('certificates/server_key.pem'), password: "dart" * 1000),
        argumentError);
    Expect.throws(() => c.usePrivateKeySync(
        localFile('certificates/server_key.pem')),
        tlsException);
    Expect.throws(() => c.usePrivateKeySync(
          localFile('certificates/server_key.pem'), password: "iHackSites"),
        tlsException);
    Expect.throws(() => c.usePrivateKeySync(
        localFile('certificates/server_key_oops.pem'),
                  password: "dartdart"),
        fileSystemException);
    Expect.throws(() => c.usePrivateKeySync(1), argumentOrTypeError);
    Expect.throws(() => c.usePrivateKeySync(null), argumentError);
    Expect.throws(() => c.usePrivateKeySync(
        localFile('certificates/server_key.pem'), password: 3),
        argumentOrTypeError);

    // Empty data.
    Expect.throws(() => c.usePrivateKeyBytes([], password: 'dartdart'),
        tlsException);
    Expect.throws(() => c.setTrustedCertificatesBytes([]), tlsException);
    Expect.throws(() => c.useCertificateChainBytes([]), tlsException);
    Expect.throws(() => c.setClientAuthoritiesBytes([]), argumentError);

    // Malformed PEM certs.
    Expect.throws(() => c.usePrivateKeySync(
        localFile('certificates/client1_key_malformed.pem'),
        password: "dartdart"),
        tlsException);
    Expect.throws(() => c.setTrustedCertificatesSync(
        localFile('certificates/trusted_certs_malformed.pem')),
        tlsException);
    Expect.throws(() => c.useCertificateChainSync(
        localFile('certificates/server_chain_malformed1.pem')),
        tlsException);
    Expect.throws(() => c.useCertificateChainSync(
        localFile('certificates/server_chain_malformed2.pem')),
        tlsException);
    Expect.throws(() => c.setClientAuthoritiesSync(
        localFile('certificates/client_authority_malformed.pem')),
        argumentError);

    c.usePrivateKeySync(
        localFile('certificates/server_key.pem'), password: "dartdart");
}

void main() {
  testUsePrivateKeyArguments();
}
