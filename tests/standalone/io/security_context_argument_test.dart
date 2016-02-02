// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

String localFile(path) => Platform.script.resolve(path).toFilePath();
List<int> readLocalFile(path) => (new File(localFile(path))).readAsBytesSync();

bool printException(e) { print(e); return true; }
bool argumentError(e) => e is ArgumentError;
bool argumentOrTypeError(e) => e is ArgumentError || e is TypeError;
bool fileSystemException(e) => e is FileSystemException;
bool tlsException(e) => e is TlsException;

void testUsePrivateKeyArguments() {
    var c = new SecurityContext();
    c.useCertificateChainBytes(readLocalFile('certificates/server_chain.pem'));
    Expect.throws(() => c.usePrivateKeyBytes(
          readLocalFile('certificates/server_key.pem'),
                        password: "dart" * 1000),
        argumentError);
    Expect.throws(() => c.usePrivateKeyBytes(
          readLocalFile('certificates/server_key.pem')),
        tlsException);
    Expect.throws(() => c.usePrivateKeyBytes(
          readLocalFile('certificates/server_key.pem'), password: "iHackSites"),
        tlsException);
    Expect.throws(() => c.usePrivateKeyBytes(
          readLocalFile('certificates/server_key_oops.pem'),
                        password: "dartdart"),
        fileSystemException);
    Expect.throws(() => c.usePrivateKeyBytes(1), argumentOrTypeError);
    Expect.throws(() => c.usePrivateKeyBytes(null), argumentError);
    Expect.throws(() => c.usePrivateKeyBytes(
          readLocalFile('certificates/server_key_oops.pem'), password: 3),
        fileSystemException);
    c.usePrivateKeyBytes(
        readLocalFile('certificates/server_key.pem'), password: "dartdart");
}

void main() {
  testUsePrivateKeyArguments();
}
