// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void testHEAD(int totalConnections) {
  HttpServer.bind().then((server) {
    server.listen((request) {
        var response = request.response;
        if (request.uri.path == "/test100") {
          response.contentLength = 100;
          response.close();
        } else if (request.uri.path == "/test200") {
          response.contentLength = 200;
          List<int> data = new List<int>.fixedLength(200, fill: 0);
          response.add(data);
          response.close();
        } else {
          assert(false);
        }
      });

    HttpClient client = new HttpClient();

    int count = 0;
    for (int i = 0; i < totalConnections; i++) {
      int len = (i % 2 == 0) ? 100 : 200;
      client.open("HEAD", "127.0.0.1", server.port, "/test$len")
        .then((request) => request.close())
        .then((HttpClientResponse response) {
          Expect.equals(len, response.contentLength);
          response.listen(
            (_) => Expect.fail("Data from HEAD request"),
            onDone: () {
              count++;
              if (count == totalConnections) {
                client.close();
                server.close();
              }
            });
        });
    }
  });
}

void main() {
  testHEAD(4);
}
