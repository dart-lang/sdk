// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:isolate");
#import("dart:io");

void setConnectionHeaders(HttpHeaders headers) {
  headers.add(HttpHeaders.CONNECTION, "my-connection-header1");
  headers.add("My-Connection-Header1", "some-value1");
  headers.add(HttpHeaders.CONNECTION, "my-connection-header2");
  headers.add("My-Connection-Header2", "some-value2");
}

void checkExpectedConnectionHeaders(HttpHeaders headers,
                                    bool persistentConnection) {
  Expect.equals("some-value1", headers.value("My-Connection-Header1"));
  Expect.equals("some-value2", headers.value("My-Connection-Header2"));
  Expect.isTrue(headers[HttpHeaders.CONNECTION].some(
      (value) => value.toLowerCase() == "my-connection-header1"));
  Expect.isTrue(headers[HttpHeaders.CONNECTION].some(
      (value) => value.toLowerCase() == "my-connection-header2"));
  if (persistentConnection) {
    Expect.equals(2, headers[HttpHeaders.CONNECTION].length);
  } else {
    Expect.equals(3, headers[HttpHeaders.CONNECTION].length);
    Expect.isTrue(headers[HttpHeaders.CONNECTION].some(
        (value) => value.toLowerCase() == "close"));
  }
}

void test(int totalConnections, bool clientPersistentConnection) {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    // Check expected request.
    Expect.equals(clientPersistentConnection, request.persistentConnection);
    Expect.equals(clientPersistentConnection, response.persistentConnection);
    checkExpectedConnectionHeaders(request.headers,
                                   request.persistentConnection);

    // Generate response. If the client signaled non-persistent
    // connection the server should not need to set it.
    if (request.persistentConnection) {
      response.persistentConnection = false;
    }
    setConnectionHeaders(response.headers);
    response.outputStream.close();
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onError = (e) => Expect.fail("Unexpected error $e");
    conn.onRequest = (HttpClientRequest request) {
      setConnectionHeaders(request.headers);
      request.persistentConnection = clientPersistentConnection;
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.isFalse(response.persistentConnection);
      checkExpectedConnectionHeaders(response.headers,
                                     response.persistentConnection);
      count++;
      if (count == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
  }
}


void main() {
  test(2, false);
  test(2, true);
}
