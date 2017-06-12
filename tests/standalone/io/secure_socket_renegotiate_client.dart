// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Client for secure_socket_renegotiate_test, that runs in a subprocess.
// The test verifies that client certificates work, if the client and server
// are in separate processes, and that connection renegotiation can request
// a client certificate to be sent.

import "dart:async";
import "dart:convert";
import "dart:io";

const HOST_NAME = "localhost";
String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

class ExpectException implements Exception {
  ExpectException(this.message);
  String toString() => message;
  String message;
}

void expectEquals(expected, actual) {
  if (actual != expected) {
    throw new ExpectException('Expected $expected, found $actual');
  }
}

void expect(condition) {
  if (!condition) {
    throw new ExpectException('');
  }
}

void runClient(int port) {
  SecureSocket
      .connect(HOST_NAME, port, context: clientContext)
      .then((SecureSocket socket) {
    X509Certificate certificate = socket.peerCertificate;
    expect(certificate != null);
    expectEquals('CN=localhost', certificate.subject);
    expectEquals('CN=myauthority', certificate.issuer);
    StreamIterator<String> input = new StreamIterator(
        socket.transform(UTF8.decoder).transform(new LineSplitter()));
    socket.writeln('first');
    input.moveNext().then((success) {
      expect(success);
      expectEquals('first reply', input.current);
      socket.renegotiate();
      socket.writeln('renegotiated');
      return input.moveNext();
    }).then((success) {
      expect(success);
      expectEquals('server renegotiated', input.current);
      X509Certificate certificate = socket.peerCertificate;
      expect(certificate != null);
      expectEquals("CN=localhost", certificate.subject);
      expectEquals("CN=myauthority", certificate.issuer);
      socket.writeln('second');
      return input.moveNext();
    }).then((success) {
      expect(success != true);
      socket.close();
    });
  });
}

void main(List<String> args) {
  runClient(int.parse(args[0]));
}
