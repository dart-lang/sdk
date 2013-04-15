// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

void testListenOn() {
  ServerSocket socket;
  HttpServer server;

  void test(void onDone()) {

    Expect.equals(socket.port, server.port);

    ReceivePort clientPort = new ReceivePort();
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
            clientPort.close();
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
  ServerSocket.bind().then((s) {
    socket = s;
    server = new HttpServer.listenOn(socket);
    ReceivePort serverPort = new ReceivePort();
    server.listen((HttpRequest request) {
      request.listen(
        (_) {},
        onDone: () {
          request.response.close();
          serverPort.close();
        });
    });

    test(() {
      test(() {
        server.close();
        Expect.throws(() => server.port);
        socket.close();
      });
    });
  });
}

void main() {
  testListenOn();
}
