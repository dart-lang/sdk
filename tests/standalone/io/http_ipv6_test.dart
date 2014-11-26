// (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:isolate";
import "dart:io";

// Client makes a HTTP 1.0 request without connection keep alive. The
// server sets a content length but still needs to close the
// connection as there is no keep alive.
void testHttpIPv6() {
  HttpServer.bind("::", 0).then((server) {
    server.listen((HttpRequest request) {
      Expect.equals(request.headers["host"][0], "[::]:${server.port}");
      Expect.equals(request.requestedUri.host, "::");
      request.response.close();
    });

    var client = new HttpClient();
    var url = Uri.parse('http://[::]:${server.port}/xxx');
    Expect.equals(url.host, '::');
    client.openUrl('GET', url)
        .then((request) => request.close())
        .then((response) {
          Expect.equals(response.statusCode, HttpStatus.OK);
        }).whenComplete(() {
          server.close();
          client.close();
        });
  });
}



void main() {
  testHttpIPv6();
}
