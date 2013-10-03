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
      .catchError((e) {
        String msg = "Unexpected error in Http Client: $e";
        var trace = getAttachedStackTrace(e);
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

void main() {
  testListenOn();
}
