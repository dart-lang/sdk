// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_write
// Tests multiple secure connections from a client to a server, hitting
// the secure connection cache.

import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";
Future<SecureServerSocket> startServer() {
  return SecureServerSocket.bind(HOST_NAME,
                                 0,
                                 CERTIFICATE).then((server) {
    server.listen((SecureSocket client) {
      client.fold(<int>[], (message, data) => message..addAll(data))
          .then((message) {
            String received = new String.fromCharCodes(message);
            Expect.isTrue(received.contains("Hello from client "));
            String name = received.substring(received.indexOf("client ") + 7);
            client.add("Welcome, client $name".codeUnits);
            client.close();
          });
    });
    return server;
  });
}

// A delay is inserted so that later connections use the secure
// connection cache to reestablish connection with a shorter handshake.
Duration delay = new Duration(milliseconds: 0);
Duration betweenTests = new Duration(milliseconds: 200);
Future testClient(server, name) {
  delay += betweenTests;
  return new Future.delayed(delay).then((_) {
    return SecureSocket.connect(HOST_NAME, server.port);
  }).then((socket) {
    socket.add("Hello from client $name".codeUnits);
    socket.close();
    return socket.fold(<int>[], (message, data) => message..addAll(data))
        .then((message) {
          Expect.listEquals("Welcome, client $name".codeUnits, message);
          return server;
        });
  });
}

void main() {
  var certificateDatabase = join(dirname(Platform.script), 'pkcert');
  SecureSocket.initialize(database: certificateDatabase,
                          password: 'dartdart');

  startServer()
      .then((server) => Future.wait(
          ['able', 'baker', 'charlie', 'dozen', 'elapse']
          .map((name) => testClient(server, name))))
      .then((servers) => servers.first.close());
}
