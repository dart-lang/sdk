// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_web_socket.web_socket_test;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:unittest/unittest.dart';

Map<String, String> get _handshakeHeaders => {
  "Upgrade": "websocket",
  "Connection": "Upgrade",
  "Sec-WebSocket-Key": "x3JJHMbDL1EzLkh9GBhXDw==",
  "Sec-WebSocket-Version": "13"
};

void main() {
  test("can communicate with a dart:io WebSocket client", () {
    return shelf_io.serve(webSocketHandler((webSocket) {
      webSocket.add("hello!");
      webSocket.first.then((request) {
        expect(request, equals("ping"));
        webSocket.add("pong");
        webSocket.close();
      });
    }), "localhost", 0).then((server) {
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
      }).whenComplete(server.close);
    });
  });

  test("negotiates the sub-protocol", () {
    return shelf_io.serve(webSocketHandler((webSocket, protocol) {
      expect(protocol, equals("two"));
      webSocket.close();
    }, protocols: ["three", "two", "x"]), "localhost", 0).then((server) {
      return WebSocket.connect('ws://localhost:${server.port}',
          protocols: ["one", "two", "three"]).then((webSocket) {
        expect(webSocket.protocol, equals("two"));
        return webSocket.close();
      }).whenComplete(server.close);
    });
  });

  group("with a set of allowed origins", () {
    var server;
    var url;
    setUp(() {
      return shelf_io.serve(webSocketHandler((webSocket) {
        webSocket.close();
      }, allowedOrigins: ["pub.dartlang.org", "GoOgLe.CoM"]), "localhost", 0)
          .then((server_) {
        server = server_;
        url = 'http://localhost:${server.port}/';
      });
    });

    tearDown(() => server.close());

    test("allows access with an allowed origin", () {
      var headers = _handshakeHeaders;
      headers['Origin'] = 'pub.dartlang.org';
      expect(http.get(url, headers: headers), hasStatus(101));
    });

    test("forbids access with a non-allowed origin", () {
      var headers = _handshakeHeaders;
      headers['Origin'] = 'dartlang.org';
      expect(http.get(url, headers: headers), hasStatus(403));
    });

    test("allows access with no origin", () {
      expect(http.get(url, headers: _handshakeHeaders), hasStatus(101));
    });

    test("ignores the case of the client origin", () {
      var headers = _handshakeHeaders;
      headers['Origin'] = 'PuB.DaRtLaNg.OrG';
      expect(http.get(url, headers: headers), hasStatus(101));
    });

    test("ignores the case of the server origin", () {
      var headers = _handshakeHeaders;
      headers['Origin'] = 'google.com';
      expect(http.get(url, headers: headers), hasStatus(101));
    });
  });

  group("HTTP errors", () {
    var server;
    var url;
    setUp(() {
      return shelf_io.serve(webSocketHandler((_) {
        fail("should not create a WebSocket");
      }), "localhost", 0).then((server_) {
        server = server_;
        url = 'http://localhost:${server.port}/';
      });
    });

    tearDown(() => server.close());

    test("404s for non-GET requests", () {
      expect(http.delete(url, headers: _handshakeHeaders), hasStatus(404));
    });

    test("404s for non-Upgrade requests", () {
      var headers = _handshakeHeaders;
      headers.remove('Connection');
      expect(http.get(url, headers: headers), hasStatus(404));
    });

    test("404s for non-websocket upgrade requests", () {
      var headers = _handshakeHeaders;
      headers['Upgrade'] = 'fblthp';
      expect(http.get(url, headers: headers), hasStatus(404));
    });

    test("400s for a missing Sec-WebSocket-Version", () {
      var headers = _handshakeHeaders;
      headers.remove('Sec-WebSocket-Version');
      expect(http.get(url, headers: headers), hasStatus(400));
    });

    test("404s for an unknown Sec-WebSocket-Version", () {
      var headers = _handshakeHeaders;
      headers['Sec-WebSocket-Version'] = '15';
      expect(http.get(url, headers: headers), hasStatus(404));
    });

    test("400s for a missing Sec-WebSocket-Key", () {
      var headers = _handshakeHeaders;
      headers.remove('Sec-WebSocket-Key');
      expect(http.get(url, headers: headers), hasStatus(400));
    });
  });

  test("throws an error if a unary function is provided with protocols", () {
    expect(() => webSocketHandler((_) => null, protocols: ['foo']),
        throwsArgumentError);
  });
}

Matcher hasStatus(int status) => completion(predicate((response) {
  expect(response, new isInstanceOf<http.Response>());
  expect(response.statusCode, equals(status));
  return true;
}));
