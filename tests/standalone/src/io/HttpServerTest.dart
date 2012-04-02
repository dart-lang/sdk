// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:isolate");

void testListenOn() {
  ServerSocket socket = new ServerSocket("127.0.0.1", 0, 5);

  socket.onError = (Exception e) {
    Expect.fail("ServerSocket closed unexpected");
  };

  void test(void onDone()) {
    HttpServer server = new HttpServer();
    Expect.throws(() => server.port);

    ReceivePort serverPort = new ReceivePort();
    server.onRequest = (HttpRequest request, HttpResponse response) {
      request.inputStream.onClosed = () {
        response.outputStream.close();
        serverPort.close();
      };
    };

    server.onError = (Exception e) {
      Expect.fail("Unexpected error in Http Server: $e");
    };

    server.listenOn(socket);
    Expect.equals(socket.port, server.port);

    HttpClient client = new HttpClient();
    HttpClientConnection conn = client.get("127.0.0.1", socket.port, "/");
    conn.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    ReceivePort clientPort = new ReceivePort();
    conn.onResponse = (HttpClientResponse response) {
      response.inputStream.onClosed = () {
        client.shutdown();
        clientPort.close();
        server.close();
        Expect.throws(() => server.port);
        onDone();
      };
    };
    conn.onError = (Exception e) {
      Expect.fail("Unexpected error in Http Client: $e");
    };
  };

  // Test two connection after each other.
  test(() {
    test(() {
      socket.close();
    });
  });
}

void main() {
  testListenOn();
}
