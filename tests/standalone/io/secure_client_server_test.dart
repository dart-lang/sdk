// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;
const CERTIFICATE = "localhost_cert";
Future<SecureServerSocket> startEchoServer() {
  return SecureServerSocket.bind(HOST,
                                 0,
                                 CERTIFICATE).then((server) {
    server.listen((SecureSocket client) {
      client.fold(<int>[], (message, data) => message..addAll(data))
          .then((message) {
            client.add(message);
            client.close();
          });
    });
    return server;
  });
}

Future testClient(server) {
  return SecureSocket.connect(HOST, server.port).then((socket) {
    socket.write("Hello server.");
    socket.close();
    return socket.fold(<int>[], (message, data) => message..addAll(data))
        .then((message) {
          Expect.listEquals("Hello server.".codeUnits, message);
          return server;
        });
  });
}

void main() {
  asyncStart();
  String certificateDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: certificateDatabase,
                          password: 'dartdart');
  InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first )
      .then((_) => startEchoServer())
      .then(testClient)
      .then((server) => server.close())
      .then((_) => asyncEnd());
}
