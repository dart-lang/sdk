// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";
Future<SecureServerSocket> startServer() {
  return SecureServerSocket.bind(SERVER_ADDRESS,
                                 0,
                                 5,
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

Future testClient(server, name) {
  return SecureSocket.connect(HOST_NAME, server.port).then((socket) {
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
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart');

  startServer()
      .then((server) => Future.wait(
          ['able', 'baker', 'charlie', 'dozen', 'elapse']
          .map((name) => testClient(server, name))))
      .then((servers) => servers.first.close());
}
