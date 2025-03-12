// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verify that the close code for an abnormally closed WebSocket is 1006
// (WebSocketStatus.abnormalClosure).
//
// See section 7.1.5 of RFC 6455:
// If _The WebSocket Connection is Closed_ and no Close control frame was
// received by the endpoint (such as could occur if the underlying transport
// connection is lost), _The WebSocket Connection Close Code_ is considered to
// be 1006.

import 'dart:async';
import 'dart:io';

// ignore: IMPORT_INTERNAL_LIBRARY
import "dart:_http"
    show
        TestingClass$_HttpRequest,
        Testing$_HttpRequest,
        Testing$_HttpConnection;

import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';

typedef _HttpRequest = TestingClass$_HttpRequest;

void main() {
  asyncStart();

  HttpRequest closeSocketAfterDelay(HttpRequest request) {
    Expect.type<_HttpRequest>(request);

    Timer(Duration(seconds: 1), () {
      (request as _HttpRequest).test$_httpConnection.test$_socket.destroy();
    });

    return request;
  }

  HttpServer.bind('localhost', 0).then((server) {
    server.map(closeSocketAfterDelay).transform(WebSocketTransformer()).drain();

    WebSocket.connect('ws://localhost:${server.port}').then((ws) {
      ws.drain().then((_) {
        Expect.equals(ws.closeCode, WebSocketStatus.abnormalClosure);

        server.close();
        asyncEnd();
      });
    });
  });
}
