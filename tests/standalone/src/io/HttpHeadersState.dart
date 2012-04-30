// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:isolate");
#import("dart:io");

void test(int totalConnections, [String body]) {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    // Cannot mutate request headers.
    Expect.throws(() => request.headers.add("X-Request-Header", "value"),
                  (e) => e is HttpException);
    Expect.equals("value", request.headers.value("X-Request-Header"));
    OutputStream stream = response.outputStream;
    // Can still mutate response headers as long as no data has been sent.
    response.headers.add("X-Response-Header", "value");
    if (body != null) {
      stream.writeString(body);
      // Cannot mutate response headers when data has been sent.
      Expect.throws(() => request.headers.add("X-Request-Header", "value2"),
                    (e) => e is HttpException);
    }
    stream.close();
    // Cannot mutate response headers when data has been sent.
    Expect.throws(() => request.headers.add("X-Request-Header", "value3"),
                  (e) => e is HttpException);
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onError = (e) => Expect.fail("Unexpected error $e");
    conn.onRequest = (HttpClientRequest request) {
      if (body != null) {
        request.contentLength = -1;
      }
      OutputStream stream = request.outputStream;
      // Can still mutate request headers as long as no data has been sent.
      request.headers.add("X-Request-Header", "value");
      if (body != null) {
        stream.writeString(body);
        // Cannot mutate request headers when data has been sent.
        Expect.throws(() => request.headers.add("X-Request-Header", "value2"),
                      (e) => e is HttpException);
      }
      stream.close();
      // Cannot mutate request headers when data has been sent.
      Expect.throws(() => request.headers.add("X-Request-Header", "value3"),
                    (e) => e is HttpException);
    };
    conn.onResponse = (HttpClientResponse response) {
      // Cannot mutate response headers.
      Expect.throws(() => response.headers.add("X-Response-Header", "value"),
                   (e) => e is HttpException);
      Expect.equals("value", response.headers.value("X-Response-Header"));
      count++;
      if (count == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
  }
}

void main() {
  test(5);
  test(5, "Hello and goodbye");
}
