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
import "dart:isolate";

void testTimeoutAfterRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.idleTimeout = null;

    server.listen((request) {
      server.idleTimeout = const Duration(milliseconds: 100);
      request.response.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      var data = "GET / HTTP/1.1\r\nContent-Length: 0\r\n\r\n";
      socket.write(data);
      socket.listen(null, onDone: () {
        socket.close();
        server.close();
      });
    });
  });
}

void testTimeoutBeforeRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.idleTimeout = const Duration(milliseconds: 100);

    server.listen((request) => request.response.close());

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.listen(null, onDone: () {
        socket.close();
        server.close();
      });
    });
  });
}

void main() {
  testTimeoutAfterRequest();
  testTimeoutBeforeRequest();
}
