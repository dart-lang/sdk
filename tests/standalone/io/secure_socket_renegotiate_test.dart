// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that client certificates work, if the client and server
// are in separate processes, and that connection renegotiation works, and
// can request a client certificate to be sent.

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";
import "package:path/path.dart";

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";


String certificateDatabase() => join(dirname(new Options().script), 'pkcert');


Future<SecureServerSocket> runServer() {
  SecureSocket.initialize(database: certificateDatabase(),
                          password: 'dartdart');

  return SecureServerSocket.bind(HOST_NAME, 0, CERTIFICATE)
    .then((SecureServerSocket server) {
      server.listen((SecureSocket socket) {
        Expect.isNull(socket.peerCertificate);

        StreamIterator<String> input =
            new StreamIterator(socket.transform(UTF8.decoder)
                                     .transform(new LineSplitter()));
        input.moveNext().then((success) {
          Expect.isTrue(success);
          Expect.equals('first', input.current);
          socket.writeln('first reply');
          return input.moveNext();
        }).then((success) {
          Expect.isTrue(success);
          Expect.equals('renegotiated', input.current);
          Expect.isNull(socket.peerCertificate);
          socket.renegotiate(requestClientCertificate: true,
                             requireClientCertificate: true,
                             useSessionCache: false);
          socket.writeln('server renegotiated');
          return input.moveNext();
        }).then((success) {
          Expect.isTrue(success);
          Expect.equals('second', input.current);
          X509Certificate certificate = socket.peerCertificate;
          Expect.isNotNull(certificate);
          Expect.equals("CN=localhost", certificate.subject);
          Expect.equals("CN=myauthority", certificate.issuer);
          server.close();
          socket.close();
        });
      });
      return server;
    });
}


void main() {
  runServer()
    .then((SecureServerSocket server) {
      final options = new Options();
      var clientScript =
          options.script.replaceFirst("_test.dart", "_client.dart");
      Expect.isTrue(clientScript.endsWith("_client.dart"));
      Process.run(options.executable,
                  [clientScript,
                   server.port.toString(),
                   certificateDatabase()])
        .then((ProcessResult result) {
          if (result.exitCode != 0) {
            print("Client failed, stdout:");
            print(result.stdout);
            print("  stderr:");
            print(result.stderr);
            Expect.fail('Client subprocess exit code: ${result.exitCode}');
          }
        });
    });
}
