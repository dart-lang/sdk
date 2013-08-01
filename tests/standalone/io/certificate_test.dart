// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that a server certificate can be verified by a client
// that loads the certificate authority certificate it depends on at runtime.

import "package:path/path.dart";
import "dart:io";
import "dart:async";

String scriptDir = dirname(new Options().script);

void main() {
  SecureSocket.initialize(database: join(scriptDir, 'pkcert'),
                          password: 'dartdart');
  runServer().then((SecureServerSocket server) {
    return Process.run(new Options().executable,
                       ['--checked',
                        join(scriptDir, 'certificate_test_client.dart'),
                        server.port.toString(),
                        join(scriptDir, 'pkcert', 'myauthority.pem')]);
  }).then((ProcessResult result) {
    if (result.exitCode != 0) {
      print("Client failed with exit code ${result.exitCode}");
      print("  stdout:");
      print(result.stdout);
      print("  stderr:");
      print(result.stderr);
      throw new AssertionError();
    }
  });
}

Future<SecureServerSocket> runServer() =>
  SecureServerSocket.bind("localhost", 0, "localhost_cert")
    .then((server) => server..listen(
        (socket) => socket.pipe(socket).then((_) => server.close())));
