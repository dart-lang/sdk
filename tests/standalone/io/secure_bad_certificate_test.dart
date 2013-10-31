// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that the bad certificate callback works.

import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";


String certificateDatabase() =>
    join(dirname(Platform.script), 'pkcert');

Future<SecureServerSocket> runServer() {
  SecureSocket.initialize(database: certificateDatabase(),
                          password: 'dartdart');

  return SecureServerSocket.bind(HOST_NAME, 0, CERTIFICATE)
      .then((SecureServerSocket server) {
    server.listen((SecureSocket socket) {
      socket.listen((_) { },
                    onDone: () {
                      socket.close();
                    });
    }, onError: (e) => Expect.isTrue(e is HandshakeException));
    return server;
  });
}


void main() {
  var clientScript = join(dirname(Platform.script),
                          'secure_bad_certificate_client.dart');

  Future clientProcess(int port, String acceptCertificate) {
    return Process.run(Platform.executable,
        [clientScript, port.toString(), acceptCertificate])
        .then((ProcessResult result) {
      if (result.exitCode != 0) {
        print("Client failed, stdout:");
        print(result.stdout);
        print("  stderr:");
        print(result.stderr);
        Expect.fail('Client subprocess exit code: ${result.exitCode}');
      }
    });
  }

  runServer().then((server) {
    Future.wait([clientProcess(server.port, 'true'),
                 clientProcess(server.port, 'false'),
                 clientProcess(server.port, 'fisk'),
                 clientProcess(server.port, 'exception')]).then((_) {
      server.close();
    });
  });
}
