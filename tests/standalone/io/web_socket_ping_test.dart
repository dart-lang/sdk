// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

library dart.io;

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:math";

part "../../../sdk/lib/io/crypto.dart";

const String webSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

void testPing(int totalConnections) {
  HttpServer.bind('localhost', 0).then((server) {
    int closed = 0;
    server.listen((request) {
      var response = request.response;
      response.statusCode = HttpStatus.SWITCHING_PROTOCOLS;
      response.headers.set(HttpHeaders.CONNECTION, "upgrade");
      response.headers.set(HttpHeaders.UPGRADE, "websocket");
      String key = request.headers.value("Sec-WebSocket-Key");
      _SHA1 sha1 = new _SHA1();
      sha1.add("$key$webSocketGUID".codeUnits);
      String accept = _CryptoUtils.bytesToBase64(sha1.close());
      response.headers.add("Sec-WebSocket-Accept", accept);
      response.headers.contentLength = 0;
      response.detachSocket().then((socket) {
        socket.drain().then((_) {
          socket.close();
          closed++;
          if (closed == totalConnections) {
            server.close();
          }
        });
      });
    });

    for (int i = 0; i < totalConnections; i++) {
      WebSocket.connect('ws://localhost:${server.port}').then((webSocket) {
        webSocket.pingInterval = const Duration(milliseconds: 100);
        webSocket.drain();
      });
    }
  });
}

void main() {
  testPing(10);
}
