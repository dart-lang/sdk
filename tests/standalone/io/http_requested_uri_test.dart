// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

const sendPath = '/path?a=b#c';
const expectedPath = '/path?a=b';

void test(String expected, Map headers) {
  asyncStart();
  HttpServer.bind("localhost", 0).then((server) {
    expected = expected.replaceAll('%PORT', server.port.toString());
    server.listen((request) {
      Expect.equals("$expected$expectedPath", request.requestedUri.toString());
      request.response.close();
    });
    HttpClient client = new HttpClient();
    client
        .get("localhost", server.port, sendPath)
        .then((request) {
          for (var v in headers.keys) {
            if (headers[v] != null) {
              request.headers.set(v, headers[v]);
            } else {
              request.headers.removeAll(v);
            }
          }
          return request.close();
        })
        .then((response) => response.drain())
        .then((_) {
          server.close();
          asyncEnd();
        });
  });
}

/// Send an HTTP request to the server containing an absolute URL
/// (RFC 3986 section 4.3) as allowed by RFC 2616 section 5.1.2.
void testAbsoluteUriInRequest() {
  asyncStart();
  Uri? requestedUri;
  HttpServer.bind("localhost", 0).then((server) {
    server.listen((request) {
      requestedUri = request.requestedUri;
      request.response.close();
    });

    Socket.connect("localhost", server.port).then((socket) {
      socket.write("GET http://google.com/ HTTP/1.1\r\n");
      socket.write("Host: google.com\r\n");
      socket.write("Connection: close\r\n");
      socket.write("\r\n");
      socket.flush().then((_) => socket.drain().then((_) {
            Expect.equals(Uri.http("google.com", "/"), requestedUri);
            socket.close();
            server.close();
            asyncEnd();
          }));
    });
  });
}

void main() {
  test('http://localhost:%PORT', {});
  test('https://localhost:%PORT', {'x-forwarded-proto': 'https'});
  test('ws://localhost:%PORT', {'x-forwarded-proto': 'ws'});
  test('http://my-host:321', {'x-forwarded-host': 'my-host:321'});
  test('http://localhost:%PORT', {'host': null});
  testAbsoluteUriInRequest();
}
