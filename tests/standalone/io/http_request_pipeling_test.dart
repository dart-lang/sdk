// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:io";

void main() {
  final int REQUEST_COUNT = 100;
  int count = 0;
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      count++;
      request.response.write(request.uri.path);
      request.response.close();
      if (request.uri.path == "/done") {
        request.response.done.then((_) {
          Expect.equals(REQUEST_COUNT + 1, count);
          server.close();
        });
      }
    });
    Socket.connect("127.0.0.1", server.port).then((s) {
      s.listen((data) {});
      for (int i = 0; i < REQUEST_COUNT; i++) {
        s.write("GET /$i HTTP/1.1\r\nX-Header-1: 111\r\n\r\n");
      }
      s.write("GET /done HTTP/1.1\r\nConnection: close\r\n\r\n");
      s.close();
    });
  });
}
