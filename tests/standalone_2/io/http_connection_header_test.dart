// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "package:expect/expect.dart";
import "dart:isolate";
import "dart:io";

void setConnectionHeaders(HttpHeaders headers) {
  headers.add(HttpHeaders.CONNECTION, "my-connection-header1");
  headers.add("My-Connection-Header1", "some-value1");
  headers.add(HttpHeaders.CONNECTION, "my-connection-header2");
  headers.add("My-Connection-Header2", "some-value2");
}

void checkExpectedConnectionHeaders(
    HttpHeaders headers, bool persistentConnection) {
  Expect.equals("some-value1", headers.value("My-Connection-Header1"));
  Expect.equals("some-value2", headers.value("My-Connection-Header2"));
  Expect.isTrue(headers[HttpHeaders.CONNECTION]
      .any((value) => value.toLowerCase() == "my-connection-header1"));
  Expect.isTrue(headers[HttpHeaders.CONNECTION]
      .any((value) => value.toLowerCase() == "my-connection-header2"));
  if (persistentConnection) {
    Expect.equals(2, headers[HttpHeaders.CONNECTION].length);
  } else {
    Expect.equals(3, headers[HttpHeaders.CONNECTION].length);
    Expect.isTrue(headers[HttpHeaders.CONNECTION]
        .any((value) => value.toLowerCase() == "close"));
  }
}

void test(int totalConnections, bool clientPersistentConnection) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      // Check expected request.
      Expect.equals(clientPersistentConnection, request.persistentConnection);
      Expect.equals(
          clientPersistentConnection, request.response.persistentConnection);
      checkExpectedConnectionHeaders(
          request.headers, request.persistentConnection);

      // Generate response. If the client signaled non-persistent
      // connection the server should not need to set it.
      if (request.persistentConnection) {
        request.response.persistentConnection = false;
      }
      setConnectionHeaders(request.response.headers);
      request.response.close();
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((HttpClientRequest request) {
        setConnectionHeaders(request.headers);
        request.persistentConnection = clientPersistentConnection;
        return request.close();
      }).then((HttpClientResponse response) {
        Expect.isFalse(response.persistentConnection);
        checkExpectedConnectionHeaders(
            response.headers, response.persistentConnection);
        response.listen((_) {}, onDone: () {
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
  test(2, false);
  test(2, true);
}
