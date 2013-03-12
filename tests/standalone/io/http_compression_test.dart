// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import 'dart:io';
import 'dart:scalarlist';

void testServerCompress() {
  void test(List<int> data) {
    HttpServer.bind().then((server) {
      server.listen((request) {
        request.response.writeBytes(data);
        request.response.close();
      });
      var client = new HttpClient();
      client.get("localhost", server.port, "/")
          .then((request) {
            request.headers.set(HttpHeaders.ACCEPT_ENCODING, "gzip");
            return request.close();
          })
          .then((response) {
            Expect.equals("gzip",
                          response.headers.value(HttpHeaders.CONTENT_ENCODING));
            response
                .transform(new ZLibInflater())
                .reduce([], (list, b) {
                  list.addAll(b);
                  return list;
                }).then((list) {
                  Expect.listEquals(data, list);
                  server.close();
                  client.close();
                });
          });
    });
  }
  test("My raw server provided data".codeUnits);
  var longBuffer = new Uint8List(1024 * 1024);
  for (int i = 0; i < longBuffer.length; i++) {
    longBuffer[i] = i & 0xFF;
  }
  test(longBuffer);
}

void main() {
  testServerCompress();
}
