// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

void testHEAD(int totalConnections) {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, totalConnections);
  server.addRequestHandler(
      (request) => request.path == "/test100",
      (HttpRequest request, HttpResponse response) {
        response.contentLength = 100;
        response.outputStream.close();
      });
  server.addRequestHandler(
      (request) => request.path == "/test200",
      (HttpRequest request, HttpResponse response) {
        response.contentLength = 200;
        List<int> data = new Uint32List(200);
        response.outputStream.write(data);
        response.outputStream.close();
      });

  HttpClient client = new HttpClient();

  int count = 0;
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn;
    int len = (i % 2 == 0) ? 100 : 200;
    if (i % 2 == 0) {
      conn = client.open("HEAD", "127.0.0.1", server.port, "/test$len");
    } else {
      conn = client.open("HEAD", "127.0.0.1", server.port, "/test$len");
    }
    conn.onError = (e) => Expect.fail("Unexpected error $e");
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(len, response.contentLength);
      response.inputStream.onData = () => Expect.fail("Data from HEAD request");
      response.inputStream.onClosed = () {
        count++;
        if (count == totalConnections) {
          client.shutdown();
          server.close();
        }
      };
    };
  }
}

void main() {
  testHEAD(4);
}
