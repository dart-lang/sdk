// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testListenOn() {
  ServerSocket socket;
  HttpServer server;

  void test(void onDone()) {
    Expect.equals(socket.port, server.port);

    HttpClient client = new HttpClient();
    client.get("127.0.0.1", socket.port, "/")
      .then((request) {
        return request.close();
      })
      .then((response) {
        response.listen(
          (_) {},
          onDone: () {
            client.close();
            onDone();
          });
      })
      .catchError((e, trace) {
        String msg = "Unexpected error in Http Client: $e";
        if (trace != null) msg += "\nStackTrace: $trace";
        Expect.fail(msg);
      });
  }

  // Test two connection after each other.
  asyncStart();
  ServerSocket.bind("127.0.0.1", 0).then((s) {
    socket = s;
    server = new HttpServer.listenOn(socket);
    Expect.equals(server.address.address, '127.0.0.1');
    Expect.equals(server.address.host, '127.0.0.1');
    server.listen((HttpRequest request) {
      request.listen(
        (_) {},
        onDone: () => request.response.close());
    });

    test(() {
      test(() {
        server.close();
        Expect.throws(() => server.port);
        Expect.throws(() => server.address);
        socket.close();
        asyncEnd();
      });
    });
  });
}


void testHttpServerZone() {
  asyncStart();
  Expect.equals(Zone.ROOT, Zone.current);
  runZoned(() {
    Expect.notEquals(Zone.ROOT, Zone.current);
    HttpServer.bind("127.0.0.1", 0).then((server) {
      Expect.notEquals(Zone.ROOT, Zone.current);
      server.listen((request) {
        Expect.notEquals(Zone.ROOT, Zone.current);
        request.response.close();
        server.close();
      });
      new HttpClient().get("127.0.0.1", server.port, '/')
        .then((request) => request.close())
        .then((response) => response.drain())
        .then((_) => asyncEnd());
    });
  });
}


void testHttpServerZoneError() {
  asyncStart();
  Expect.equals(Zone.ROOT, Zone.current);
  runZoned(() {
    Expect.notEquals(Zone.ROOT, Zone.current);
    HttpServer.bind("127.0.0.1", 0).then((server) {
      Expect.notEquals(Zone.ROOT, Zone.current);
      server.listen((request) {
        Expect.notEquals(Zone.ROOT, Zone.current);
        request.listen((_) {}, onError: (error) {
          Expect.notEquals(Zone.ROOT, Zone.current);
          server.close();
          throw error;
        });
      });
      Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.write('GET / HTTP/1.1\r\nContent-Length: 100\r\n\r\n');
        socket.write('some body');
        socket.close();
        socket.listen(null);
      });
    });
  }, onError: (e) {
    asyncEnd();
  });
}


void main() {
  testListenOn();
  testHttpServerZone();
  testHttpServerZoneError();
}
