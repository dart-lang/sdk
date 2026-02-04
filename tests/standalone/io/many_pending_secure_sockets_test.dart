// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

// Verifies that a large number of secure sockets can be connected
// simultaneously.
//
// See https://github.com/flutter/flutter/issues/170723

import 'dart:async';
import "dart:io";

// Should be more than the number of threads that the OS can easily create.
const numConnections = 2000;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(
    localFile('certificates/server_key.pem'),
    password: 'dartdart',
  );
SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

Future<SecureServerSocket> startServer() async {
  final server = await SecureServerSocket.bind(
    InternetAddress.loopbackIPv4,
    0,
    serverContext,
  );
  server.listen((SecureSocket client) async {
    client.write('Connected!');
    await client.flush();
    client.listen((_) {}, onDone: () => client.close());
  });
  return server;
}

Future<RawSecureSocket> connectSocket(int port) async {
  final socket = await RawSecureSocket.connect(
    InternetAddress.loopbackIPv4,
    port,
    context: clientContext,
  );
  await socket.firstWhere((e) => e == RawSocketEvent.read);
  return socket;
}

main() async {
  final server = await startServer();
  final tests = <Future>[];
  final allConnected = Completer<void>();

  for (var i = 0; i < numConnections;) {
    // Performing thousands of simultaneous TLS connections can result in
    // timeouts. So connect 20 sockets at a time.
    final socketConnections = <Future<RawSecureSocket>>[];
    for (var j = 0; i < numConnections && j < 20; i++, j++) {
      socketConnections.add(connectSocket(server.port));
    }

    for (var socket in await Future.wait(socketConnections)) {
      Future<void> delayAndClose() async {
        await allConnected.future;
        await Future.delayed(
          Duration(seconds: 6), // More than the thread pool timeout.
        );
        socket.close();
      }

      tests.add(delayAndClose());
    }
  }
  allConnected.complete();
  await Future.wait(tests);
  server.close();
}
