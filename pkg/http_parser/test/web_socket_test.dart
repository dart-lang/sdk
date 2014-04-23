// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_parser.web_socket_test;

import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:unittest/unittest.dart';

void main() {
  test("a client can communicate with a WebSocket server", () {
    return HttpServer.bind("localhost", 0).then((server) {
      server.transform(new WebSocketTransformer()).listen((webSocket) {
        webSocket.add("hello!");
        webSocket.first.then((request) {
          expect(request, equals("ping"));
          webSocket.add("pong");
          webSocket.close();
        });
      });

      var client = new HttpClient();
      return client.openUrl("GET", Uri.parse("http://localhost:${server.port}"))
          .then((request) {
        request.headers
            ..set("Connection", "Upgrade")
            ..set("Upgrade", "websocket")
            ..set("Sec-WebSocket-Key", "x3JJHMbDL1EzLkh9GBhXDw==")
            ..set("Sec-WebSocket-Version", "13");
        return request.close();
      }).then((response) => response.detachSocket()).then((socket) {
        var webSocket = new CompatibleWebSocket(socket, serverSide: false);

        var n = 0;
        return webSocket.listen((message) {
          if (n == 0) {
            expect(message, equals("hello!"));
            webSocket.add("ping");
          } else if (n == 1) {
            expect(message, equals("pong"));
            webSocket.close();
            server.close();
          } else {
            fail("Only expected two messages.");
          }
          n++;
        }).asFuture();
      });
    });
  });

  test("a server can communicate with a WebSocket client", () {
    return HttpServer.bind("localhost", 0).then((server) {
      server.listen((request) {
        var response = request.response;
        response.statusCode = 101;
        response.headers
            ..set("Connection", "Upgrade")
            ..set("Upgrade", "websocket")
            ..set("Sec-WebSocket-Accept", CompatibleWebSocket.signKey(
                request.headers.value('Sec-WebSocket-Key')));
        response.contentLength = 0;
        response.detachSocket().then((socket) {
          var webSocket = new CompatibleWebSocket(socket);
          webSocket.add("hello!");
          webSocket.first.then((request) {
            expect(request, equals("ping"));
            webSocket.add("pong");
            webSocket.close();
          });
        });
      });

      return WebSocket.connect('ws://localhost:${server.port}')
          .then((webSocket) {
        var n = 0;
        return webSocket.listen((message) {
          if (n == 0) {
            expect(message, equals("hello!"));
            webSocket.add("ping");
          } else if (n == 1) {
            expect(message, equals("pong"));
            webSocket.close();
            server.close();
          } else {
            fail("Only expected two messages.");
          }
          n++;
        }).asFuture();
      });
    });
  });
}
