// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/untrusted_server_chain.pem
// OtherResources=certificates/untrusted_server_key.pem
// OtherResources=certificates/trusted_certs.pem
// OtherResources=https_unauthorized_client.dart

// This test verifies that secure connections that fail due to
// unauthenticated certificates throw exceptions in HttpClient.

import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext untrustedServerContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/untrusted_server_chain.pem'))
  ..usePrivateKey(localFile('certificates/untrusted_server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

Future<SecureServerSocket> runServer() {
  return HttpServer
      .bindSecure(HOST_NAME, 0, untrustedServerContext, backlog: 5)
      .then((server) {
    server.listen((HttpRequest request) {
      request.listen((_) {}, onDone: () {
        request.response.close();
      });
    }, onError: (e) {
      if (e is! HandshakeException) throw e;
    });
    return server;
  });
}

void main() {
  var clientScript = localFile('https_unauthorized_client.dart');
  Future clientProcess(int port) {
    return Process
        .run(Platform.executable, [clientScript, port.toString()]).then(
            (ProcessResult result) {
      if (result.exitCode != 0 || !result.stdout.contains('SUCCESS')) {
        print("Client failed");
        print("  stdout:");
        print(result.stdout);
        print("  stderr:");
        print(result.stderr);
        Expect.fail('Client subprocess exit code: ${result.exitCode}');
      }
    });
  }

  runServer().then((server) {
    clientProcess(server.port).then((_) {
      server.close();
    });
  });
}
