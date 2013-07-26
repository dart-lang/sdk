// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Client for secure_bad_certificate_test, that runs in a subprocess.
// The test verifies that the client bad certificate callback works.

import "dart:async";
import "dart:io";

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

void runClient(int port, result) {
  bool badCertificateCallback(X509Certificate certificate) {
    expect('CN=localhost' == certificate.subject);
    expect('CN=myauthority' == certificate.issuer);
    expect(result != 'exception');  // Throw exception if one is requested.
    if (result == 'true') result = true;
    if (result == 'false') result = false;
    return result;
  }

  SecureSocket.connect(HOST_NAME,
                       port,
                       onBadCertificate: badCertificateCallback)
      .then((SecureSocket socket) {
        expect(result);
        socket.close();
      },
      onError: (error) {
        expect(result != true);
        if (result == false) {
          expect(error is HandshakeException);
        } else if (result == 'exception') {
          expect(error is ExpectException);
        } else {
          expect(error is ArgumentError);
        }
      });
}


void main() {
  final args = new Options().arguments;
  SecureSocket.initialize();
  runClient(int.parse(args[0]), args[1]);
}
