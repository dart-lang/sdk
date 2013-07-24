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


void testPing(int totalConnections) {
  HttpServer.bind('localhost', 0).then((server) {
    server.transform(new WebSocketTransformer()).listen((webSocket) {
      webSocket.pingInterval = const Duration(milliseconds: 500);
      webSocket.drain();
    });

    var futures = [];
    for (int i = 0; i < totalConnections; i++) {
      futures.add(
          WebSocket.connect('ws://localhost:${server.port}').then((webSocket) {
        webSocket.pingInterval = const Duration(milliseconds: 500);
        webSocket.drain();
        new Timer(const Duration(seconds: 2), () {
          // Should not be closed yet.
          Expect.equals(null, webSocket.closeCode);
          webSocket.close();
        });
        return webSocket.done;
      }));
    }
    Future.wait(futures).then((_) => server.close());
  });
}


void main() {
  testPing(10);
}
