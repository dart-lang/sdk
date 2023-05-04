// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:convert";
import "dart:io";
// ignore: IMPORT_INTERNAL_LIBRARY
import "dart:_http"
    show
        TestingClass$_SHA1,
        TestingClass$_WebSocketImpl,
        Testing$_WebSocketImpl;

import "package:expect/expect.dart";

typedef _SHA1 = TestingClass$_SHA1;
typedef _WebSocketImpl = TestingClass$_WebSocketImpl;

const String webSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

void testPing(int totalConnections) {
  HttpServer.bind('localhost', 0).then((server) {
    int closed = 0;
    server.listen((request) {
      var response = request.response;
      response.statusCode = HttpStatus.switchingProtocols;
      response.headers.set(HttpHeaders.connectionHeader, "upgrade");
      response.headers.set(HttpHeaders.upgradeHeader, "websocket");
      String? key = request.headers.value("Sec-WebSocket-Key");
      _SHA1 sha1 = new _SHA1();
      sha1.add("$key$webSocketGUID".codeUnits);
      String accept = base64Encode(sha1.close());
      response.headers.add("Sec-WebSocket-Accept", accept);
      response.headers.contentLength = 0;
      response.detachSocket().then((socket) {
        socket.destroy();
      });
    });

    int closeCount = 0;
    for (int i = 0; i < totalConnections; i++) {
      WebSocket.connect('ws://localhost:${server.port}').then((webSocket) {
        webSocket.pingInterval = const Duration(milliseconds: 100);
        webSocket.listen((message) {
          Expect.fail("unexpected message");
        }, onDone: () {
          closeCount++;
          if (closeCount == totalConnections) {
            server.close();
          }
        });
      });
    }
  });
}

void testPingCancelledOnClose() {
  HttpServer.bind('localhost', 0).then((server) {
    server
        .transform(new WebSocketTransformer())
        .listen((webSocket) => webSocket.drain());

    Testing$_WebSocketImpl.connect('ws://localhost:${server.port}', null, null)
        .then((webSocket) {
      Expect.type<_WebSocketImpl>(webSocket);

      webSocket.pingInterval = const Duration(seconds: 100);
      webSocket.listen((message) {
        Expect.fail("unexpected message");
      }, onDone: () {
        Expect.isFalse((webSocket as _WebSocketImpl).test$_pingTimer?.isActive);
        server.close();
      });

      webSocket.close();
    });
  });
}

void main() {
  testPing(10);
  testPingCancelledOnClose();
}
