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

testEmptyProtocol() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      WebSocketTransformer.upgrade(request).then((websocket) {
        websocket.close();
      });
    });
    WebSocket.connect("ws://127.0.0.1:${server.port}/", protocols: []).then(
        (client) {
      Expect.isNull(client.protocol);
      client.close();
      server.close();
    });
  });
}

testProtocol(List<String> protocols, String used) {
  selector(List<String> receivedProtocols) {
    Expect.listEquals(protocols, receivedProtocols);
    return used;
  }

  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      WebSocketTransformer
          .upgrade(request, protocolSelector: selector)
          .then((websocket) {
        Expect.equals(used, websocket.protocol);
        websocket.close();
      });
    });
    WebSocket
        .connect("ws://127.0.0.1:${server.port}/", protocols: protocols)
        .then((client) {
      Expect.equals(used, client.protocol);
      client.close();
      server.close();
    });
  });
}

testProtocolHandler() {
  // Test throwing an error.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      selector(List<String> receivedProtocols) {
        throw "error";
      }

      WebSocketTransformer.upgrade(request, protocolSelector: selector).then(
          (websocket) {
        Expect.fail('error expected');
      }, onError: (error) {
        Expect.equals('error', error);
      });
    });
    WebSocket.connect("ws://127.0.0.1:${server.port}/",
        protocols: ["v1.example.com"]).then((client) {
      Expect.fail('error expected');
    }, onError: (error) {
      server.close();
    });
  });

  // Test returning another protocol.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      selector(List<String> receivedProtocols) => "v2.example.com";
      WebSocketTransformer.upgrade(request, protocolSelector: selector).then(
          (websocket) {
        Expect.fail('error expected');
      }, onError: (error) {
        Expect.isTrue(error is WebSocketException);
      });
    });
    WebSocket.connect("ws://127.0.0.1:${server.port}/",
        protocols: ["v1.example.com"]).then((client) {
      Expect.fail('error expected');
    }, onError: (error) {
      server.close();
    });
  });
}

void main() {
  testEmptyProtocol();
  testProtocol(["v1.example.com", "v2.example.com"], "v1.example.com");
  testProtocol(["v1.example.com", "v2.example.com"], "v2.example.com");
  testProtocolHandler();
}
