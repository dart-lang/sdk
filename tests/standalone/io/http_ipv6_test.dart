// (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

// Client makes a HTTP 1.0 request without connection keep alive. The
// server sets a content length but still needs to close the
// connection as there is no keep alive.
void testHttpIPv6() {
  asyncStart();
  HttpServer.bind("::", 0).then((server) {
    server.listen((HttpRequest request) {
      Expect.equals(request.headers["host"][0], "[::1]:${server.port}");
      Expect.equals(request.requestedUri.host, "::1");
      request.response.close();
    });

    var client = new HttpClient();
    var url = Uri.parse('http://[::1]:${server.port}/xxx');
    Expect.equals(url.host, '::1');
    client
        .openUrl('GET', url)
        .then((request) => request.close())
        .then((response) {
      Expect.equals(response.statusCode, HttpStatus.OK);
    }).whenComplete(() {
      server.close();
      client.close();
      asyncEnd();
    });
  });
}

void main() {
  testHttpIPv6();
}
