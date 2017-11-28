// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Client for secure_bad_certificate_test, that runs in a subprocess.
// The test verifies that the client bad certificate callback works.

import "dart:async";
import "dart:io";

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

class ExpectException implements Exception {
  ExpectException(this.message);
  String toString() => "ExpectException: $message";
  String message;
}

void expect(condition) {
  if (!condition) {
    throw new ExpectException('');
  }
}

const HOST_NAME = "localhost";

Future runClients(int port) {
  var testFutures = [];
  for (int i = 0; i < 20; ++i) {
    testFutures.add(SecureSocket
        .connect(HOST_NAME, port, context: clientContext)
        .then((SecureSocket socket) {
      expect(false);
    }, onError: (e) {
      expect(e is HandshakeException || e is SocketException);
    }));
  }
  return Future.wait(testFutures);
}

void main(List<String> args) {
  runClients(int.parse(args[0])).then((_) => print('SUCCESS'));
}
